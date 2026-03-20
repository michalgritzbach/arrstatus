<p align="center">
  <img src="assets/logo.png" alt="Arrstatus" width="360">
</p>

Monitors download clients (qBittorrent, SABnzbd) and *arr services (Radarr, Sonarr, Lidarr). Two frontends, one config file:

- **macOS menubar app** — native SwiftUI, macOS 15+
- **Waybar widget** — Python script for Hyprland/Linux

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

## License

Open Community License (OCL) v1 — free for non-commercial use, internal commercial use allowed, resale/commercialization requires a separate license. See [LICENSE](LICENSE).
