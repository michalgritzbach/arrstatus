# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Arrstatus is a macOS 15+ menubar application that monitors download clients (qBittorrent, SABnzbd) and *arr services (Radarr, Sonarr). It displays aggregated download counts and speeds in the menubar with detailed status in a native macOS dropdown menu.

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

## Architecture

### Layered Architecture
- **Presentation Layer**: SwiftUI views using MenuBarExtra for menubar integration
- **State Management**: `@Observable` StatusAggregator for reactive updates
- **Service Layer**: API clients for each service (QBittorrentClient, SABnzbdClient, RadarrClient, SonarrClient)
- **Domain Layer**: Codable models for API responses
- **Configuration Layer**: Hardcoded constants in `AppConfiguration.swift`

### App Structure
- **Entry Point**: `ArrstatusApp.swift` uses `MenuBarExtra` (not WindowGroup) for menubar app
- **StatusAggregator**: Central orchestrator marked with `@Observable`, injected via environment
- **Polling**: Timer-based polling every 5 seconds, fetches from all services in parallel
- **Views**: Access aggregator via `@Environment(StatusAggregator.self)`

### File Organization
```
Arrstatus/
├── ArrstatusApp.swift                    # Entry point with MenuBarExtra
├── Configuration/
│   └── AppConfiguration.swift            # Hardcoded API endpoints and credentials
├── Models/
│   ├── DownloadClient/
│   │   ├── QBittorrentModels.swift      # Torrent info and transfer models
│   │   └── SABnzbdModels.swift          # Queue and slot models
│   ├── ArrService/
│   │   ├── RadarrModels.swift           # Movie queue items with TMDB ID
│   │   └── SonarrModels.swift           # Series queue items with episode info
│   └── AggregatedStatus.swift            # Combined status structure
├── Services/
│   ├── DownloadClients/
│   │   ├── QBittorrentClient.swift      # Cookie-based auth client
│   │   └── SABnzbdClient.swift          # API key auth client
│   ├── ArrServices/
│   │   ├── RadarrClient.swift           # Radarr v3 API client
│   │   └── SonarrClient.swift           # Sonarr v3 API client
│   └── StatusAggregator.swift            # Orchestrator with @Observable
├── Views/
│   ├── MenuBarContentView.swift         # Native menu dropdown content
│   └── MenuBarLabel.swift                # Menubar icon/text
└── Utilities/
    └── FormatHelpers.swift               # Speed/byte formatting
```

### Testing Framework
- Uses Swift Testing framework (not XCTest) - note the `import Testing` and `@Test` attribute syntax
- Unit tests: `ArrstatusTests/ArrstatusTests.swift`
- UI tests: `ArrstatusUITests/`

## Key Patterns

### API Integration
- **qBittorrent**: Cookie-based authentication (login required, session cookie stored)
- **SABnzbd**: API key in query parameter
- **Radarr/Sonarr**: X-Api-Key header authentication
- All clients use URLSession with 30s timeout
- Parallel fetching with `async let` for performance
- Result types for error handling per service

### State Management with @Observable
- StatusAggregator is marked `@Observable` (Swift 5.9+)
- Automatic change tracking for all properties
- Views re-render when observed properties change
- No need for `@Published` or manual `objectWillChange` calls

### Configuration
- All settings hardcoded in `AppConfiguration.swift` enum
- Organized by service (QBittorrent, SABnzbd, Radarr, Sonarr)
- Includes base URLs, API keys, web UI URLs, and polling interval

### Testing
Tests use Swift Testing framework syntax:
- Mark test functions with `@Test` attribute (not `func testXYZ()`)
- Use `#expect(...)` for assertions (not `XCTAssert...`)
- Test functions can be `async throws`
