#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."

if ! command -v rsvg-convert &>/dev/null; then
    echo "rsvg-convert not found. Install librsvg:" >&2
    echo "  Arch:   sudo pacman -S librsvg" >&2
    echo "  Debian: sudo apt install librsvg2-bin" >&2
    echo "  macOS:  brew install librsvg" >&2
    exit 1
fi

echo "Exporting logo..."
rsvg-convert -w 720  -h 240  "$ROOT/logo.svg" -o "$SCRIPT_DIR/logo.png"
rsvg-convert -w 1440 -h 480  "$ROOT/logo.svg" -o "$SCRIPT_DIR/logo@2x.png"

echo "Exporting icon..."
for size in 16 32 64 128 256 512; do
    rsvg-convert -w "$size" -h "$size" "$SCRIPT_DIR/icon.svg" -o "$SCRIPT_DIR/icon-${size}.png"
done

echo "Done:"
ls -lh "$SCRIPT_DIR"/*.png
