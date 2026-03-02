.PHONY: test test-flutter test-python setup-test-venv

# Run both test suites.
test: test-flutter test-python

# ---------------------------------------------------------------------------
# Flutter unit tests (headless, no display needed)
# ---------------------------------------------------------------------------

test-flutter:
	@echo "\n==> Flutter tests"
	flutter test --reporter=expanded

# ---------------------------------------------------------------------------
# Python API tests (in-process via FastAPI TestClient, no server spawned)
# ---------------------------------------------------------------------------

test-python: setup-test-venv
	@echo "\n==> Python tests"
	cd server && source .venv/bin/activate && pytest tests/ -v

# Install test dependencies into the existing server venv (once).
setup-test-venv:
	@cd server && source .venv/bin/activate && \
		pip install -q -r requirements-test.txt
