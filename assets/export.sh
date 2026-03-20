#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCODE_APPICONSET="$SCRIPT_DIR/../Arrstatus/Assets.xcassets/AppIcon.appiconset"

if ! command -v rsvg-convert &>/dev/null; then
    echo "rsvg-convert not found. Install librsvg:" >&2
    echo "  Arch:   sudo pacman -S librsvg" >&2
    echo "  Debian: sudo apt install librsvg2-bin" >&2
    echo "  macOS:  brew install librsvg" >&2
    exit 1
fi

# ── Logo ──────────────────────────────────────────────────────────────────────

echo "Exporting logo..."
rsvg-convert -w 720  -h 240  "$SCRIPT_DIR/logo.svg" -o "$SCRIPT_DIR/logo.png"
rsvg-convert -w 1440 -h 480  "$SCRIPT_DIR/logo.svg" -o "$SCRIPT_DIR/logo@2x.png"

# ── Icon (flat, for README / waybar / general use) ────────────────────────────

echo "Exporting icon..."
for size in 16 32 64 128 256 512; do
    rsvg-convert -w "$size" -h "$size" "$SCRIPT_DIR/icon.svg" -o "$SCRIPT_DIR/icon-${size}.png"
done

# ── Icon (rounded, for Xcode / macOS app) ────────────────────────────────────

echo "Exporting Xcode app icon..."
rsvg-convert -w 16   -h 16   "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_16x16.png"
rsvg-convert -w 32   -h 32   "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_16x16@2x.png"
rsvg-convert -w 32   -h 32   "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_32x32.png"
rsvg-convert -w 64   -h 64   "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_32x32@2x.png"
rsvg-convert -w 128  -h 128  "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_128x128.png"
rsvg-convert -w 256  -h 256  "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_128x128@2x.png"
rsvg-convert -w 256  -h 256  "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_256x256.png"
rsvg-convert -w 512  -h 512  "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_256x256@2x.png"
rsvg-convert -w 512  -h 512  "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_512x512.png"
rsvg-convert -w 1024 -h 1024 "$SCRIPT_DIR/icon-xcode.svg" -o "$XCODE_APPICONSET/icon_512x512@2x.png"

echo "Done."
