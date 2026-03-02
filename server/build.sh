#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Build the Python server into a self-contained PyInstaller binary.
#
# Output is written to  ../assets/bin/python_server  (macOS/Linux)
#                    or  ../assets/bin/python_server.exe  (Windows via Git Bash)
#
# Usage:
#   cd server/
#   ./build.sh            # macOS / Linux
#   bash build.sh         # Windows (Git Bash)
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SCRIPT_DIR/../assets/bin"
VENV_DIR="$SCRIPT_DIR/.venv"
PLATFORM="$(uname -s | tr '[:upper:]' '[:lower:]')"

echo "==> Platform : $PLATFORM"
echo "==> Output   : $DIST_DIR"

mkdir -p "$DIST_DIR"

# Create (or reuse) a virtual environment so we don't touch the system Python.
if [ ! -d "$VENV_DIR" ]; then
  echo "==> Creating venv at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

pip install --upgrade pip --quiet
pip install -r "$SCRIPT_DIR/requirements.txt" --quiet
pip install pyinstaller --quiet

# Build.
pyinstaller \
  --onefile \
  --name python_server \
  --distpath "$DIST_DIR" \
  --specpath /tmp/pyinstaller_spec \
  --workpath /tmp/pyinstaller_build \
  --clean \
  "$SCRIPT_DIR/main.py"

deactivate

echo ""
echo "==> Done. Binary: $DIST_DIR/python_server"
