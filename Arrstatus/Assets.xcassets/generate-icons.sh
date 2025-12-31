#!/bin/bash

# Script to generate all required app icon sizes from icon.svg
# Requires: rsvg-convert (install with: brew install librsvg)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SVG_FILE="$SCRIPT_DIR/icon.svg"
OUTPUT_DIR="$SCRIPT_DIR/AppIcon.appiconset"

if [ ! -f "$SVG_FILE" ]; then
    echo "Error: icon.svg not found at $SVG_FILE"
    exit 1
fi

if ! command -v rsvg-convert &> /dev/null; then
    echo "Error: rsvg-convert not found. Install with: brew install librsvg"
    exit 1
fi

echo "Generating app icons from icon.svg..."

# Generate all required sizes
rsvg-convert -w 16 -h 16 "$SVG_FILE" > "$OUTPUT_DIR/icon_16x16.png"
rsvg-convert -w 32 -h 32 "$SVG_FILE" > "$OUTPUT_DIR/icon_16x16@2x.png"
rsvg-convert -w 32 -h 32 "$SVG_FILE" > "$OUTPUT_DIR/icon_32x32.png"
rsvg-convert -w 64 -h 64 "$SVG_FILE" > "$OUTPUT_DIR/icon_32x32@2x.png"
rsvg-convert -w 128 -h 128 "$SVG_FILE" > "$OUTPUT_DIR/icon_128x128.png"
rsvg-convert -w 256 -h 256 "$SVG_FILE" > "$OUTPUT_DIR/icon_128x128@2x.png"
rsvg-convert -w 256 -h 256 "$SVG_FILE" > "$OUTPUT_DIR/icon_256x256.png"
rsvg-convert -w 512 -h 512 "$SVG_FILE" > "$OUTPUT_DIR/icon_256x256@2x.png"
rsvg-convert -w 512 -h 512 "$SVG_FILE" > "$OUTPUT_DIR/icon_512x512.png"
rsvg-convert -w 1024 -h 1024 "$SVG_FILE" > "$OUTPUT_DIR/icon_512x512@2x.png"

echo "✅ Generated 10 icon files in $OUTPUT_DIR"
echo ""
echo "Icon sizes:"
echo "  16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024"
