# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Arrstatus monitors download clients (qBittorrent, SABnzbd) and *arr services (Radarr, Sonarr, Lidarr). It has two frontends sharing the same config file (`~/.config/arrstatus/arrstatus.conf`):

- **macOS app** (`Arrstatus/`): macOS 15+ menubar application built with SwiftUI
- **Waybar widget** (`waybar/arrstatus.py`): Python script for Hyprland/waybar on Linux

## Build and Development Commands

### Building
```bash
# Build the project
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj build

# Build for specific configuration
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj -configuration Debug build
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj -configuration Release build
```

### Testing
```bash
# Run all tests
xcodebuild test -scheme Arrstatus -project Arrstatus.xcodeproj

# Run only unit tests
xcodebuild test -scheme Arrstatus -project Arrstatus.xcodeproj -only-testing:ArrstatusTests

# Run only UI tests
xcodebuild test -scheme Arrstatus -project Arrstatus.xcodeproj -only-testing:ArrstatusUITests

# Run a specific test
xcodebuild test -scheme Arrstatus -project Arrstatus.xcodeproj -only-testing:ArrstatusTests/ArrstatusTests/example
```

### Cleaning
```bash
# Clean build artifacts
xcodebuild clean -scheme Arrstatus -project Arrstatus.xcodeproj
```

### Waybar widget
```bash
# Test output directly
python3 waybar/arrstatus.py
```

## Configuration

Both frontends read `~/.config/arrstatus/arrstatus.conf` (INI format). The file is created with defaults on first run if it doesn't exist. See `arrstatus.conf.example` for all options.

The macOS app watches the file for changes (via modification date polling every 5s) and reconfigures automatically. No restart required.

Credentials (passwords, API keys) are stored in plain text in the config file — there is no keychain integration.

## Architecture

### Layered Architecture
- **Presentation Layer**: SwiftUI views using MenuBarExtra for menubar integration
- **State Management**: `@Observable` StatusAggregator for reactive updates
- **Service Layer**: API clients for each service (QBittorrentClient, SABnzbdClient, RadarrClient, SonarrClient, LidarrClient)
- **Domain Layer**: Codable models for API responses
- **Configuration Layer**: `SettingsManager` parses `~/.config/arrstatus/arrstatus.conf`

### App Structure
- **Entry Point**: `ArrstatusApp.swift` uses `MenuBarExtra` (not WindowGroup) for menubar app
- **StatusAggregator**: Central orchestrator marked with `@Observable`, injected via environment
- **Polling**: Timer-based polling (configurable, default 10s), fetches from all services in parallel
- **Views**: Access aggregator via `@Environment(StatusAggregator.self)`

### File Organization
```
Arrstatus/
├── ArrstatusApp.swift                    # Entry point with MenuBarExtra
├── Models/
│   ├── Settings/
│   │   └── ServiceConfiguration.swift   # AppSettings + per-service config structs
│   ├── DownloadClient/
│   │   ├── QBittorrentModels.swift      # Torrent info and transfer models
│   │   └── SABnzbdModels.swift          # Queue and slot models
│   ├── ArrService/
│   │   ├── RadarrModels.swift           # Movie queue items with TMDB ID
│   │   ├── SonarrModels.swift           # Series queue items with episode info
│   │   └── LidarrModels.swift           # Artist/album queue items
│   └── AggregatedStatus.swift           # Combined status structure
├── Services/
│   ├── DownloadClients/
│   │   ├── QBittorrentClient.swift      # Cookie-based auth client
│   │   └── SABnzbdClient.swift          # API key auth client
│   ├── ArrServices/
│   │   ├── RadarrClient.swift           # Radarr v3 API client
│   │   ├── SonarrClient.swift           # Sonarr v3 API client
│   │   └── LidarrClient.swift           # Lidarr v1 API client
│   ├── StatusAggregator.swift           # Orchestrator with @Observable
│   └── SettingsManager.swift            # INI config file reader + file watcher
├── Views/
│   ├── MenuBarContentView.swift         # Native menu dropdown content
│   └── MenuBarLabel.swift               # Menubar icon/text
└── Utilities/
    └── FormatHelpers.swift              # Speed/byte formatting

waybar/
└── arrstatus.py                         # Waybar widget (Python 3, no dependencies)

arrstatus.conf.example                   # Annotated example config file
```

### Testing Framework
- Uses Swift Testing framework (not XCTest) - note the `import Testing` and `@Test` attribute syntax
- Unit tests: `ArrstatusTests/ArrstatusTests.swift`
- UI tests: `ArrstatusUITests/`

## Key Patterns

### API Integration
- **qBittorrent**: Cookie-based authentication (login required, session cookie stored)
- **SABnzbd**: API key in query parameter
- **Radarr/Sonarr**: X-Api-Key header authentication, v3 API
- **Lidarr**: X-Api-Key header authentication, v1 API
- All clients use URLSession with 30s timeout
- Parallel fetching with `async let` for performance
- Result types for error handling per service

### State Management with @Observable
- StatusAggregator is marked `@Observable` (Swift 5.9+)
- Automatic change tracking for all properties
- Views re-render when observed properties change
- No need for `@Published` or manual `objectWillChange` calls

### Configuration
- `SettingsManager` reads and parses the INI config file on init
- Watches for file changes by polling modification date every 5s
- Emits `configurationDidChange` via Combine when settings change
- `StatusAggregator` subscribes to `configurationDidChange` and reconfigures clients
- Settings/Onboarding/Keychain views are stubbed out (dead code kept to avoid Xcode project file edits)

### Testing
Tests use Swift Testing framework syntax:
- Mark test functions with `@Test` attribute (not `func testXYZ()`)
- Use `#expect(...)` for assertions (not `XCTAssert...`)
- Test functions can be `async throws`
