# App Icon Setup

This directory contains the app icon assets for Arrstatus.

## Files

- **`icon.svg`** - Source vector icon (master file)
- **`AppIcon.appiconset/`** - Generated PNG icons at various sizes
- **`generate-icons.sh`** - Script to regenerate icons from SVG

## Icon Sizes

macOS apps require icons at multiple sizes for different contexts:

| Size      | Use Case                          | Files                                    |
|-----------|-----------------------------------|------------------------------------------|
| 16x16     | Menubar, dock (small)             | `icon_16x16.png` (@1x)                   |
| 32x32     | Menubar retina, list views        | `icon_16x16@2x.png`, `icon_32x32.png`    |
| 64x64     | List views retina                 | `icon_32x32@2x.png`                      |
| 128x128   | Dock (normal displays)            | `icon_128x128.png`                       |
| 256x256   | Dock (retina), thumbnails         | `icon_128x128@2x.png`, `icon_256x256.png`|
| 512x512   | Quick Look, About box             | `icon_256x256@2x.png`, `icon_512x512.png`|
| 1024x1024 | App Store, retina Quick Look      | `icon_512x512@2x.png`                    |

## Updating the Icon

1. Edit `icon.svg` with your design tool (e.g., Inkscape, Figma, Sketch)
2. Run the generation script:
   ```bash
   ./generate-icons.sh
   ```
3. Build the app - Xcode will automatically pick up the new icons

## Requirements

The generation script requires `rsvg-convert` from librsvg:

```bash
brew install librsvg
```

## Manual Icon Generation

If you prefer to generate icons manually:

```bash
# Example: Generate 512x512 icon
rsvg-convert -w 512 -h 512 icon.svg > AppIcon.appiconset/icon_512x512.png
```

## Design Guidelines

- **Format**: SVG (vector) for maximum flexibility
- **Canvas**: Square aspect ratio (1:1)
- **Style**: Simple, recognizable at small sizes
- **Colors**: Consider both light and dark menu bars
- **Testing**: Test icon at 16x16 - if it looks good there, it works everywhere

## Current Icon

The current icon is designed for the Arrstatus menubar app, monitoring download clients and *arr services.
