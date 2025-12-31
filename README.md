# Arrstatus

A lightweight macOS menubar application that monitors download clients (qBittorrent, SABnzbd) and *arr services (Radarr, Sonarr), displaying real-time download statistics and active items in a native dropdown menu.

## Features

- **Real-time Monitoring**: Polls all configured services every 5 seconds
- **Native macOS Integration**: Uses native MenuBar dropdown with system-styled sections
- **Download Client Support**:
  - **qBittorrent**: Shows download/upload speeds with active torrent counts
  - **SABnzbd**: Displays download speed with active download counts
- ***arr Service Support**:
  - **Radarr**: Lists active movie downloads with progress, ETA, and status
  - **Sonarr**: Lists active TV episode downloads with series/episode info
- **Web UI Integration**: Click any item to open directly in your browser
- **Error Handling**: Gracefully handles service failures without crashing

## Requirements

- macOS 15.4 or later
- Xcode 16.0 or later (for building from source)
- Running instances of:
  - qBittorrent (optional)
  - SABnzbd (optional)
  - Radarr (optional)
  - Sonarr (optional)

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/michalgritzbach/arrstatus.git
cd arrstatus
```

2. Open the project in Xcode:
```bash
open Arrstatus.xcodeproj
```

3. Configure your services (see Configuration section below)

4. Build and run:
```bash
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj build
```

Or press `Cmd+R` in Xcode to build and run.

## Configuration

Edit `Arrstatus/Configuration/AppConfiguration.swift` with your service details:

```swift
enum AppConfiguration {
    enum PollingInterval {
        static let seconds: TimeInterval = 5.0
    }

    enum QBittorrent {
        static let baseURL = "http://your-server:8080"
        static let username = "admin"
        static let password = "your-password"
        static let webUIURL = "http://your-server:8080"
    }

    enum SABnzbd {
        static let baseURL = "http://your-server:8080"
        static let apiKey = "your-api-key-here"
        static let webUIURL = "http://your-server:8080"
    }

    enum Radarr {
        static let baseURL = "http://your-server:7878"
        static let apiKey = "your-api-key-here"
        static let webUIURL = "http://your-server:7878"
    }

    enum Sonarr {
        static let baseURL = "http://your-server:8989"
        static let apiKey = "your-api-key-here"
        static let webUIURL = "http://your-server:8989"
    }
}
```

### Finding API Keys

- **qBittorrent**: Username and password from Web UI settings
- **SABnzbd**: Config → General → API Key
- **Radarr/Sonarr**: Settings → General → Security → API Key

## Architecture

### Key Components

- **StatusAggregator**: Central orchestrator using Swift's `@Observable` macro. Polls all services in parallel every 5 seconds and aggregates results.
- **API Clients**: Dedicated clients for each service (QBittorrentClient, SABnzbdClient, RadarrClient, SonarrClient) handling authentication and API requests.
- **Models**: Codable structs for JSON parsing with computed properties for display logic.
- **Views**: Native SwiftUI components for menubar integration.

### Authentication Methods

- **qBittorrent**: Cookie-based authentication with session management
- **SABnzbd**: API key in query parameters
- **Radarr/Sonarr**: X-Api-Key header authentication

## Development

### Project Structure

```
Arrstatus/
├── ArrstatusApp.swift              # Entry point with MenuBarExtra
├── Configuration/
│   └── AppConfiguration.swift      # Service configuration
├── Models/
│   ├── DownloadClient/            # qBittorrent & SABnzbd models
│   ├── ArrService/                # Radarr & Sonarr models
│   └── AggregatedStatus.swift     # Combined status
├── Services/
│   ├── DownloadClients/           # Download client API clients
│   ├── ArrServices/               # *arr service API clients
│   └── StatusAggregator.swift     # Orchestrator
├── Views/
│   ├── MenuBarContentView.swift   # Native menu dropdown
│   └── MenuBarLabel.swift         # Menubar icon/text
└── Utilities/
    └── FormatHelpers.swift        # Formatting utilities
```

### Building

```bash
# Debug build
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj -configuration Debug build

# Release build
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj -configuration Release build
```

### Running

```bash
# Run from Xcode
open Arrstatus.xcodeproj
# Press Cmd+R

# Or build and run
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj build
open /Users/$USER/Library/Developer/Xcode/DerivedData/Arrstatus-*/Build/Products/Debug/Arrstatus.app
```

## Testing

The project includes comprehensive unit tests for all models, utilities, and business logic.

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme Arrstatus -project Arrstatus.xcodeproj

# Run only unit tests
xcodebuild test -scheme Arrstatus -project Arrstatus.xcodeproj -only-testing:ArrstatusTests

# Run specific test
xcodebuild test -scheme Arrstatus -project Arrstatus.xcodeproj -only-testing:ArrstatusTests/FormatHelpersTests
```

## Troubleshooting

### Connection Issues

- Verify your services are accessible from your Mac
- Check firewall settings
- Ensure API keys are correct
- Test URLs in a browser first

### Authentication Failures

- **qBittorrent**: Check username/password in Web UI settings
- **SABnzbd/Radarr/Sonarr**: Verify API key hasn't been regenerated

### No Data Showing

- Check Console.app for error logs (filter for "Arrstatus")
- Verify services have active downloads/items in queue
- Ensure polling interval isn't too long (default: 5 seconds)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Open Community License (OCL) v1.

**What this means:**
- ✅ **Non-commercial users**: Full freedom to use, modify, and share
- ✅ **Commercial users**: Can use internally for your own infrastructure
- ❌ **Commercial users**: Cannot resell or commercialize derivatives without a separate license
- 📖 See the [LICENSE](LICENSE) file for full details

## Support

If you encounter issues or have questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the Troubleshooting section above

---

**Note**: This application requires valid API credentials for the services you want to monitor. It makes HTTP requests to your configured services and does not collect or transmit any data externally.
