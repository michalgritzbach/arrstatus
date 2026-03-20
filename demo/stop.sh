#!/usr/bin/env bash
set -euo pipefail

CONF_DIR="$HOME/.config/arrstatus"
CONF="$CONF_DIR/arrstatus.conf"
BACKUP="$CONF_DIR/arrstatus.conf.real"
PID_FILE="$CONF_DIR/mock_server.pid"

# ── Stop mock server ──────────────────────────────────────────────────────────

if [[ -f "$PID_FILE" ]]; then
    PID="$(cat "$PID_FILE")"
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "Mock server stopped (PID $PID)."
    else
        echo "Mock server was not running."
    fi
    rm -f "$PID_FILE"
else
    echo "No PID file found — mock server may not have been started."
fi

# ── Restore config ────────────────────────────────────────────────────────────

if [[ -f "$BACKUP" ]]; then
    cp "$BACKUP" "$CONF"
    rm -f "$BACKUP"
    echo "Real config restored."
else
    echo "No backup found — config left as-is."
fi
