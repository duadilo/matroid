"""
Headless API tests for the Matroid Python server.

Uses FastAPI's TestClient (backed by httpx) — no real server process is
started, so tests run entirely in-process and are fast and deterministic.

Run:
    cd server && source .venv/bin/activate && pytest tests/ -v
"""

import base64
import io
import os
import shutil
from unittest.mock import AsyncMock, MagicMock, patch

import openpyxl
import pytest
from fastapi.testclient import TestClient

from main import _workbook, app

client = TestClient(app)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def reset_workbook():
    """Clear server-side workbook state before every test."""
    _workbook["bytes"] = None
    _workbook["name"] = None
    yield
    _workbook["bytes"] = None
    _workbook["name"] = None


def _make_xlsx(rows: list[tuple] | None = None) -> bytes:
    """Build a minimal in-memory xlsx and return its bytes."""
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.append(["Name", "Score"])
    for row in rows or [("Alice", 95), ("Bob", 82)]:
        ws.append(list(row))
    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()


def _load(filename: str = "test.xlsx", rows=None):
    """Helper: POST /load and return the response."""
    xlsx = _make_xlsx(rows)
    return client.post(
        "/load",
        files={"file": (filename, xlsx, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")},
    )


# ---------------------------------------------------------------------------
# /health
# ---------------------------------------------------------------------------


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


# ---------------------------------------------------------------------------
# /load
# ---------------------------------------------------------------------------


def test_load_success():
    xlsx = _make_xlsx()
    r = client.post(
        "/load",
        files={"file": ("data.xlsx", xlsx)},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "loaded"
    assert body["filename"] == "data.xlsx"
    assert body["size_bytes"] == len(xlsx)


def test_load_missing_file_returns_422():
    r = client.post("/load")
    assert r.status_code == 422


def test_load_replaces_previous_file():
    _load("first.xlsx")
    _load("second.xlsx")
    # Export should return the second file
    r = client.get("/export")
    assert r.status_code == 200
    assert 'filename="second.xlsx"' in r.headers["content-disposition"]


# ---------------------------------------------------------------------------
# /process
# ---------------------------------------------------------------------------


def test_process_without_load_returns_400():
    r = client.post("/process", json={})
    assert r.status_code == 400
    assert "No file loaded" in r.json()["detail"]


def test_process_after_load():
    _load()
    r = client.post("/process", json={"operation": "summary"})
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "processed"
    assert body["params"]["operation"] == "summary"


def test_process_empty_params():
    _load()
    r = client.post("/process", json={})
    assert r.status_code == 200
    assert r.json()["params"] == {}


def test_process_preserves_arbitrary_params():
    _load()
    params = {"sheet": "Sales", "col": "Revenue", "agg": "sum"}
    r = client.post("/process", json=params)
    assert r.status_code == 200
    assert r.json()["params"] == params


# ---------------------------------------------------------------------------
# /export
# ---------------------------------------------------------------------------


def test_export_without_load_returns_400():
    r = client.get("/export")
    assert r.status_code == 400


def test_export_returns_original_bytes():
    xlsx = _make_xlsx()
    client.post("/load", files={"file": ("out.xlsx", xlsx)})
    r = client.get("/export")
    assert r.status_code == 200
    assert r.content == xlsx


def test_export_content_type():
    _load()
    r = client.get("/export")
    assert "spreadsheetml" in r.headers["content-type"]


def test_export_content_disposition():
    _load("report.xlsx")
    r = client.get("/export")
    assert 'attachment' in r.headers["content-disposition"]
    assert "report.xlsx" in r.headers["content-disposition"]


# ---------------------------------------------------------------------------
# /unload
# ---------------------------------------------------------------------------


def test_unload_clears_state():
    _load()
    r = client.post("/unload")
    assert r.status_code == 200
    assert r.json() == {"status": "unloaded"}
    # State should be cleared
    assert client.post("/process", json={}).status_code == 400
    assert client.get("/export").status_code == 400


def test_unload_is_idempotent():
    r1 = client.post("/unload")
    r2 = client.post("/unload")
    assert r1.status_code == 200
    assert r2.status_code == 200


# ---------------------------------------------------------------------------
# Full workflow
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# /execute — Python
# ---------------------------------------------------------------------------


def _execute(language: str, code: str, timeout: int = 10):
    return client.post("/execute", json={"language": language, "code": code, "timeout": timeout})


def test_execute_python_print():
    r = _execute("python", 'print("hello")')
    assert r.status_code == 200
    body = r.json()
    assert "hello" in body["stdout"]
    assert body["error"] is None


def test_execute_python_multiline_print():
    r = _execute("python", 'print("a")\nprint("b")')
    assert r.status_code == 200
    assert "a" in r.json()["stdout"]
    assert "b" in r.json()["stdout"]


def test_execute_python_restricted_import():
    r = _execute("python", "import os")
    assert r.status_code == 200
    body = r.json()
    assert body["error"] is not None


def test_execute_python_syntax_error():
    r = _execute("python", "def foo(:")
    assert r.status_code == 200
    body = r.json()
    assert body["error"] is not None
    assert "SyntaxError" in body["error"]


def test_execute_python_timeout():
    r = _execute("python", "while True: pass", timeout=1)
    assert r.status_code == 200
    body = r.json()
    assert body["error"] is not None
    assert "timed out" in body["error"].lower()


def test_execute_python_get_data_no_file():
    r = _execute("python", "print(get_data())")
    assert r.status_code == 200
    assert "[]" in r.json()["stdout"]


def test_execute_python_get_data_with_file():
    _load()
    r = _execute("python", "print(len(get_data()))")
    assert r.status_code == 200
    # _make_xlsx adds 2 data rows
    assert "2" in r.json()["stdout"]


def test_execute_python_get_headers():
    _load()
    r = _execute("python", "print(get_headers())")
    assert r.status_code == 200
    stdout = r.json()["stdout"]
    assert "Name" in stdout
    assert "Score" in stdout


def test_execute_python_summarize():
    _load()
    r = _execute("python", "s = summarize(); print(s['Name']['count'])")
    assert r.status_code == 200
    assert "2" in r.json()["stdout"]


def test_execute_python_filter_rows():
    _load()
    r = _execute("python", "print(len(filter_rows('Name', 'Alice')))")
    assert r.status_code == 200
    assert "1" in r.json()["stdout"]


def test_execute_python_execution_time_reported():
    r = _execute("python", "pass")
    assert r.status_code == 200
    assert isinstance(r.json()["execution_time_ms"], int)


# ---------------------------------------------------------------------------
# /execute — JavaScript
# ---------------------------------------------------------------------------


def test_execute_javascript_no_node():
    with patch("main.shutil.which", return_value=None):
        r = _execute("javascript", 'console.log("hi")')
    assert r.status_code == 200
    body = r.json()
    assert body["error"] is not None
    assert "Node.js" in body["error"]


@pytest.mark.skipif(shutil.which("node") is None, reason="Node.js not installed")
def test_execute_javascript_print():
    r = _execute("javascript", 'console.log("hello from js")')
    assert r.status_code == 200
    body = r.json()
    assert body["error"] is None
    assert "hello from js" in body["stdout"]


@pytest.mark.skipif(shutil.which("node") is None, reason="Node.js not installed")
def test_execute_javascript_get_data_no_file():
    r = _execute("javascript", "console.log(getData().length)")
    assert r.status_code == 200
    assert "0" in r.json()["stdout"]


# ---------------------------------------------------------------------------
# /execute — unknown language
# ---------------------------------------------------------------------------


def test_execute_unknown_language():
    r = _execute("ruby", "puts 'hello'")
    assert r.status_code == 400
    assert "ruby" in r.json()["detail"].lower()


# ---------------------------------------------------------------------------
# Full workflow
# ---------------------------------------------------------------------------


def test_full_load_process_export_unload_cycle():
    xlsx = _make_xlsx([("Carol", 99), ("Dave", 77)])

    # Load
    r = client.post("/load", files={"file": ("cycle.xlsx", xlsx)})
    assert r.status_code == 200

    # Process
    r = client.post("/process", json={"op": "mean"})
    assert r.status_code == 200
    assert r.json()["filename"] == "cycle.xlsx"

    # Export — bytes round-trip
    r = client.get("/export")
    assert r.status_code == 200
    assert r.content == xlsx

    # Unload
    r = client.post("/unload")
    assert r.status_code == 200

    # Subsequent process should fail
    assert client.post("/process", json={}).status_code == 400


# ---------------------------------------------------------------------------
# Chat endpoint tests
# ---------------------------------------------------------------------------


class TestChatModels:
    def test_no_keys_returns_empty(self):
        with patch.dict(os.environ, {}, clear=True):
            r = client.get("/chat/models")
            assert r.status_code == 200
            assert r.json()["providers"] == {}

    def test_with_openai_key(self):
        with patch.dict(os.environ, {"OPENAI_API_KEY": "sk-test"}, clear=True):
            r = client.get("/chat/models")
            assert r.status_code == 200
            providers = r.json()["providers"]
            assert "openai" in providers
            assert len(providers["openai"]) > 0

    def test_with_all_keys(self):
        env = {
            "OPENAI_API_KEY": "sk-test",
            "ANTHROPIC_API_KEY": "sk-ant-test",
            "GOOGLE_API_KEY": "goog-test",
        }
        with patch.dict(os.environ, env, clear=True):
            r = client.get("/chat/models")
            providers = r.json()["providers"]
            assert set(providers.keys()) == {"openai", "anthropic", "gemini"}


class TestChatStream:
    def test_unknown_provider(self):
        r = client.post(
            "/chat/stream",
            json={
                "provider": "unknown",
                "model": "x",
                "messages": [{"role": "user", "content": "hi"}],
            },
        )
        assert r.status_code == 400

    def test_missing_key_yields_error_event(self):
        with patch.dict(os.environ, {}, clear=True):
            r = client.post(
                "/chat/stream",
                json={
                    "provider": "openai",
                    "model": "gpt-4o",
                    "messages": [{"role": "user", "content": "hi"}],
                },
            )
            assert r.status_code == 200
            body = r.text
            assert "event: error" in body

    def test_openai_stream_tokens(self):
        async def mock_stream(req):
            for token in ["Hello", " world"]:
                yield token

        from main import _STREAM_PROVIDERS
        orig = _STREAM_PROVIDERS["openai"]
        _STREAM_PROVIDERS["openai"] = mock_stream
        try:
            r = client.post(
                "/chat/stream",
                json={
                    "provider": "openai",
                    "model": "gpt-4o",
                    "messages": [{"role": "user", "content": "hi"}],
                },
            )
            assert r.status_code == 200
            lines = [l for l in r.text.split("\n") if l.startswith("data:")]
            assert "data: Hello" in lines
            assert "data:  world" in lines
            assert "data: [DONE]" in lines
        finally:
            _STREAM_PROVIDERS["openai"] = orig

    def test_anthropic_stream_tokens(self):
        async def mock_stream(req):
            for token in ["Bonjour"]:
                yield token

        from main import _STREAM_PROVIDERS
        orig = _STREAM_PROVIDERS["anthropic"]
        _STREAM_PROVIDERS["anthropic"] = mock_stream
        try:
            r = client.post(
                "/chat/stream",
                json={
                    "provider": "anthropic",
                    "model": "claude-sonnet-4-20250514",
                    "messages": [{"role": "user", "content": "hi"}],
                },
            )
            assert r.status_code == 200
            assert "data: Bonjour" in r.text
        finally:
            _STREAM_PROVIDERS["anthropic"] = orig

    def test_gemini_stream_tokens(self):
        async def mock_stream(req):
            for token in ["Hola"]:
                yield token

        from main import _STREAM_PROVIDERS
        orig = _STREAM_PROVIDERS["gemini"]
        _STREAM_PROVIDERS["gemini"] = mock_stream
        try:
            r = client.post(
                "/chat/stream",
                json={
                    "provider": "gemini",
                    "model": "gemini-2.0-flash",
                    "messages": [{"role": "user", "content": "hi"}],
                },
            )
            assert r.status_code == 200
            assert "data: Hola" in r.text
        finally:
            _STREAM_PROVIDERS["gemini"] = orig

    def test_with_attachment_no_crash(self):
        """Ensure requests with base64 attachments don't crash parsing."""
        img_data = base64.b64encode(b"\x89PNG\r\n").decode()

        async def mock_stream(req):
            yield "ok"

        from main import _STREAM_PROVIDERS
        orig = _STREAM_PROVIDERS["openai"]
        _STREAM_PROVIDERS["openai"] = mock_stream
        try:
            r = client.post(
                "/chat/stream",
                json={
                    "provider": "openai",
                    "model": "gpt-4o",
                    "messages": [
                        {
                            "role": "user",
                            "content": "describe",
                            "attachments": [
                                {"media_type": "image/png", "data": img_data}
                            ],
                        }
                    ],
                },
            )
            assert r.status_code == 200
            assert "data: ok" in r.text
        finally:
            _STREAM_PROVIDERS["openai"] = orig

    def test_client_api_key_override(self):
        """api_keys in request body should be used instead of env var."""

        async def mock_stream(req):
            yield "used-override"

        from main import _STREAM_PROVIDERS
        orig = _STREAM_PROVIDERS["openai"]
        _STREAM_PROVIDERS["openai"] = mock_stream
        try:
            with patch.dict(os.environ, {}, clear=True):
                r = client.post(
                    "/chat/stream",
                    json={
                        "provider": "openai",
                        "model": "gpt-4o",
                        "messages": [{"role": "user", "content": "hi"}],
                        "api_keys": {"openai": "sk-client-key"},
                    },
                )
                assert r.status_code == 200
                assert "data: used-override" in r.text
        finally:
            _STREAM_PROVIDERS["openai"] = orig

    def test_newline_escaping(self):
        """Tokens containing newlines should be escaped in SSE output."""

        async def mock_stream(req):
            yield "line1\nline2"

        from main import _STREAM_PROVIDERS
        orig = _STREAM_PROVIDERS["openai"]
        _STREAM_PROVIDERS["openai"] = mock_stream
        try:
            r = client.post(
                "/chat/stream",
                json={
                    "provider": "openai",
                    "model": "gpt-4o",
                    "messages": [{"role": "user", "content": "hi"}],
                },
            )
            assert r.status_code == 200
            assert "data: line1\\nline2" in r.text
        finally:
            _STREAM_PROVIDERS["openai"] = orig
