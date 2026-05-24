#!/usr/bin/env bash
# Muesli macOS setup script
# Requires: Python 3.10+, Homebrew (https://brew.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Muesli macOS Setup ==="

# ── Python check ──────────────────────────────────────────────────────────────
PYTHON=""
for candidate in python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" &>/dev/null; then
        ver=$("$candidate" -c "import sys; print(sys.version_info >= (3,10))")
        if [ "$ver" = "True" ]; then
            PYTHON="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    echo "ERROR: Python 3.10+ is required."
    echo "Install it with: brew install python@3.12"
    exit 1
fi

echo "Using Python: $($PYTHON --version)"

# ── System dependencies via Homebrew ──────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "WARNING: Homebrew not found. Install it from https://brew.sh"
    echo "         then re-run this script."
    exit 1
fi

echo "Checking system dependencies..."

if ! command -v ffmpeg &>/dev/null; then
    echo "Installing ffmpeg..."
    brew install ffmpeg
else
    echo "  ffmpeg: OK"
fi

if ! brew list portaudio &>/dev/null 2>&1; then
    echo "Installing portaudio..."
    brew install portaudio
else
    echo "  portaudio: OK"
fi

# ── Virtual environment ───────────────────────────────────────────────────────
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    "$PYTHON" -m venv .venv
fi

source .venv/bin/activate
echo "Using venv: $(which python)"

echo "Upgrading pip..."
pip install --upgrade pip --quiet

# ── Python dependencies ───────────────────────────────────────────────────────
echo "Installing Python dependencies..."
pip install -r requirements.txt

# pyaudio requires portaudio headers; install if possible
if pip install pyaudio --quiet 2>/dev/null; then
    echo "  pyaudio: OK"
else
    echo "  pyaudio: skipped (sounddevice will be used instead)"
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "To launch Muesli:"
echo "  source .venv/bin/activate"
echo "  python muesli_gui.py"
echo ""
echo "Notes:"
echo "  - macOS will prompt for microphone access on first recording."
echo "  - Transcription runs on CPU (Apple Silicon GPU is not yet supported"
echo "    by faster-whisper; the 'fast' Whisper model is recommended)."
echo "  - The global hotkey agent is Windows-only; use Ctrl+R inside the app"
echo "    to start/stop recording."
