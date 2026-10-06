<p align="center">
  <img src="assets/logo.png" alt="Arrstatus" width="360">
</p>

Monitors download clients (qBittorrent, SABnzbd) and *arr services (Radarr, Sonarr, Lidarr). Three frontends, one config file:

- **macOS menubar app** — native SwiftUI, macOS 15+
- **Waybar widget** — Python script for Hyprland/Linux
- **Omarchy bar widget** — Quickshell plugin wrapping the same script

## Configuration

Both frontends read `~/.config/arrstatus/arrstatus.conf`. The file is created automatically with commented-out defaults on first run.

```ini
[general]
poll_interval = 10

[qbittorrent]
enabled = true
url = http://localhost:8080
username = admin
password = yourpassword

[sabnzbd]
enabled = true
url = http://localhost:8080
api_key = yourapikey

[radarr]
enabled = true
url = http://localhost:7878
api_key = yourapikey

[sonarr]
enabled = true
url = http://localhost:8989
api_key = yourapikey

[lidarr]
enabled = true
url = http://localhost:8686
api_key = yourapikey
```

`webui_url` is optional for each service — if set, clicking items opens that URL instead of `url`.

Changes are picked up automatically without restarting either frontend.

## macOS App

### Requirements

- macOS 15.0 or later

### Installation

**Download release:**

1. Download `Arrstatus-v*.zip` from [Releases](https://github.com/michalgritzbach/Arrstatus/releases)
2. Unzip, then remove the quarantine flag (required for unsigned apps):
   ```bash
   xattr -cr Arrstatus.app
   ```
3. Move to `/Applications`, right-click → Open on first launch

**Build from source:**

```bash
git clone https://github.com/michalgritzbach/arrstatus.git
cd arrstatus
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj build
```

### What it shows

The menubar label shows total download speed and active item count. The dropdown shows:

- **qBittorrent**: download speed + torrent count, upload speed + torrent count
- **SABnzbd**: download speed + active download count
- **Radarr**: each active movie with progress/ETA
- **Sonarr**: each active episode (`Series  S01E02  Episode Title`) with progress/ETA
- **Lidarr**: each active album (`Artist – Album (year)`) with progress/ETA

Click any item to open it in your browser.

## Waybar Widget

### Setup

```bash
mkdir -p ~/.config/waybar/scripts
cp waybar/arrstatus.py ~/.config/waybar/scripts/arrstatus.py
chmod +x ~/.config/waybar/scripts/arrstatus.py
```

Add to your waybar config:

```json
"custom/arrstatus": {
    "exec": "~/.config/waybar/scripts/arrstatus.py",
    "interval": 10,
    "return-type": "json",
    "format": "{}",
    "tooltip": true
}
```

Add `"custom/arrstatus"` to your `modules-left`, `modules-center`, or `modules-right`.

**CSS classes** for `style.css`:

```css
#custom-arrstatus.downloading { color: #a6e3a1; }
#custom-arrstatus.error        { color: #f38ba8; }
/* .idle has empty text so it's hidden by default */
```

### What it shows

Bar text: `↓ 5.2 MB/s  ≡ 3` (speed + active count).

Tooltip mirrors the macOS dropdown — sections separated by horizontal rules, service names bold, status text dimmed.

The script also has a structured mode for frontends that draw their own UI:

```bash
waybar/arrstatus.py --json
```

It prints one report per run — totals, then a per-service block with its speed,
active count, error (if any) and queue items (title, status, percent, ETA).

## Omarchy Bar Widget

Omarchy 4 replaced Waybar with a Quickshell-based bar. `omarchy/` is a bar-widget
plugin: the bar carries the headline, and a popup panel carries the detail.

- **Bar** — `↓ 5.2 MB/s  ≡ 3`, or a warning glyph when a service is failing.
  Nothing downloading and nothing broken means nothing in the bar.
- **Panel** — a hero line with the totals, then one section per service:
  its name, its own headline (speed for the download clients, item count for the
  *arrs, the error when there is one), and a row per queue item with title,
  percentage, progress meter, status and ETA. Stalled items and errors take the
  theme's urgent color. Clicking a row or a section header opens that service's
  web UI.

It runs `waybar/arrstatus.py --json`, which fetches every enabled service in one
pass and prints a structured report; the panel draws it.

### Setup

Link (or copy) the plugin directory into the Omarchy plugin path, then enable it:

```bash
ln -sfn "$PWD/omarchy" ~/.config/omarchy/plugins/michal.arrstatus
omarchy plugin enable michal.arrstatus --section right
```

The widget finds the script at `../waybar/arrstatus.py` relative to itself, so a
symlinked checkout needs no further configuration. A standalone install can drop
`arrstatus.py` next to `Panel.qml` instead.

### Interactions

- Bar icon: left = panel, right = open the first configured web UI, middle = refresh.
- Panel: `j`/`k` scroll, `r` or Enter refresh, `o` open the first web UI,
  Tab moves to the neighboring bar panel, Esc closes.
- IPC: `omarchy-shell michal.arrstatus <open|close|toggle|refresh>`.

### Settings

Per-widget settings live in the `bar.layout` entry in `~/.config/omarchy/shell.json`:

```json
{ "id": "michal.arrstatus", "interval": 5 }
```

| Key | Default | Meaning |
|---|---|---|
| `interval` | `5` | Seconds between polls |
| `command` | — | Script path or shell command to run instead of the bundled script; it is called with `--json` |
| `fontSize` | bar body size | Bar label size |

Do **not** name a setting `exec` or `source`: the bar treats any layout entry
carrying those keys as a built-in command/QML module and never loads the plugin.

### Notes

- The panel is built from Omarchy's own `qs.Ui` components (`Panel`,
  `KeyboardPanel`, `PanelHero`, …), so it inherits the theme, popup placement and
  keyboard handling — at the cost of depending on those internals.
- The bar runs one widget instance per monitor, so a two-monitor setup polls twice
  per interval.
- Plugin code is only reloaded from a symlinked checkout by `omarchy restart shell`;
  in-place plugin directories also hot-reload on save.

## License

Open Community License (OCL) v1 — free for non-commercial use, internal commercial use allowed, resale/commercialization requires a separate license. See [LICENSE](LICENSE).
