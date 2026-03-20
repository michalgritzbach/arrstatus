# Changelog

All notable changes to Arrstatus are documented here.

## [0.2.0] - 2026-03-20

### Added
- **Waybar widget** (`waybar/arrstatus.py`) for Hyprland/wayland desktops — reads the same config file as the macOS app, outputs waybar JSON with Pango markup tooltips
- **Lidarr monitoring** — tracks music download queue with artist, album, and release year display
- **File-based configuration** — settings are now read from `~/.config/arrstatus/arrstatus.conf` (INI format); default config is created on first run if absent
- Config file is watched for changes and reloaded automatically (no restart required)
- `webui_url` option per service to open a different URL in the browser than the API base URL
- Example config file (`arrstatus.conf.example`)
- Swift and Python test suites; CI now runs both on every push

### Changed
- Removed the settings GUI — configure everything by editing the config file
- Sonarr entries now display as `Series  S01E02  Episode Title` (episode title included when available)
- Lidarr entries display as `Artist – Album (Year)`
- Synced display format between macOS menubar app and waybar tooltip
- Updated README with configuration instructions, waybar setup, and CSS class reference
- Updated CI workflow: removed pinned Xcode 16.2 selection; added Python lint (`ruff`) and test job on ubuntu-latest

### Fixed
- qBittorrent connection handling and empty-state display
- Python import order (`Fix Python imports`)
- Swift model init synthesis for Xcode 16.2 compatibility (`SonarrEpisode.title`, `LidarrAlbum.releaseDate`)

## [0.1.2] - 2025-12-31

### Added
- `bump-version` script for managing version numbers across the project

### Fixed
- qBittorrent connection and empty state handling
- Corrected release notes

## [0.1.1] - 2025-12-31

### Added
- App icon

### Fixed
- Release notes content

## [0.1.0] - 2025-12-31

### Added
- Initial macOS 15+ menubar app monitoring qBittorrent, SABnzbd, Radarr, and Sonarr
- Native macOS dropdown showing download speeds, active counts, and per-item status
- Cookie-based qBittorrent authentication; API key auth for SABnzbd, Radarr, Sonarr
- Parallel polling of all services on a configurable interval
- User preferences window with secure credential storage (Keychain)
- GitHub Actions workflows for test, build, and release
- README and LICENSE
- Unit tests

[0.2.0]: https://github.com/michalgritzbach/arrstatus/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/michalgritzbach/arrstatus/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/michalgritzbach/arrstatus/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/michalgritzbach/arrstatus/releases/tag/v0.1.0
