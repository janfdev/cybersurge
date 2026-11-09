#!/usr/bin/env bash
set -e

echo "=== CyberSurge: Neon Protocol - Deployment Script ==="

mkdir -p build/web

GODOT_BIN="${GODOT_BIN:-$USERPROFILE/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"

if [ -f "$GODOT_BIN" ]; then
    echo "[1/3] Running automated headless test suite..."
    "$GODOT_BIN" --headless -s tests/TestRunner.gd
    echo "[Test suite passed successfully]"
else
    echo "Warning: Godot binary not found at $GODOT_BIN"
fi

echo "[2/3] Verifying deployment artifacts..."
test -f Dockerfile && echo "  - Dockerfile: OK"
test -f nginx.conf && echo "  - nginx.conf: OK"
test -f export_presets.cfg && echo "  - export_presets.cfg: OK"

echo "[3/3] Ready for Coolify / Dokploy deployment."
echo "To build Docker image locally: docker build -t cybersurge-game:latest ."
