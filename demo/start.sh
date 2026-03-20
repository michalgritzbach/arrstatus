#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_DIR="$HOME/.config/arrstatus"
CONF="$CONF_DIR/arrstatus.conf"
BACKUP="$CONF_DIR/arrstatus.conf.real"
PID_FILE="$CONF_DIR/mock_server.pid"

# ── Check not already running ─────────────────────────────────────────────────

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "Mock server is already running (PID $(cat "$PID_FILE"))."
    echo "Run demo/stop.sh first if you want to restart."
    exit 1
fi

# ── Start mock server ─────────────────────────────────────────────────────────

mkdir -p "$CONF_DIR"
python3 "$SCRIPT_DIR/mock_server.py" &
echo $! > "$PID_FILE"
echo "Mock server started (PID $!)."

# Give the servers a moment to bind their ports
sleep 0.5

# ── Swap config ───────────────────────────────────────────────────────────────

if [[ -f "$CONF" ]] && [[ ! -f "$BACKUP" ]]; then
    cp "$CONF" "$BACKUP"
    echo "Real config backed up to $BACKUP"
elif [[ -f "$BACKUP" ]]; then
    echo "Backup already exists — real config was already swapped."
fi

cp "$SCRIPT_DIR/demo.conf" "$CONF"
echo "Demo config installed."
echo
echo "All services are live. Take your screenshot, then run demo/stop.sh"
