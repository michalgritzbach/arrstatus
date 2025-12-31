# Arrstatus

A lightweight macOS menubar application that monitors download clients (qBittorrent, SABnzbd) and *arr services (Radarr, Sonarr), displaying real-time download statistics and active items in a native dropdown menu.

## Features

- **Real-time Monitoring**: Polls all configured services with customizable interval (5-60 seconds)
- **Native macOS Integration**: Uses native MenuBar dropdown with system-styled sections
- **User Preferences Window**: Native macOS 15+ Settings window for configuration
- **Secure Credential Storage**: Passwords and API keys stored in macOS Keychain
- **Per-Service Controls**: Enable/disable services individually with toggles
- **Connection Testing**: Test credentials before saving
- **Download Client Support**:
  - **qBittorrent**: Shows download/upload speeds with active torrent counts
  - **SABnzbd**: Displays download speed with active download counts
- ***arr Service Support**:
  - **Radarr**: Lists active movie downloads with progress, ETA, and status
  - **Sonarr**: Lists active TV episode downloads with series/episode info
- **Web UI Integration**: Click any item to open directly in your browser (supports custom URLs)
- **Error Handling**: Gracefully handles service failures without crashing
- **Comprehensive Testing**: 56 unit tests covering all components

## Requirements

- macOS 15.4 or later
- Xcode 16.0 or later (for building from source)
- Running instances of:
  - qBittorrent (optional)
  - SABnzbd (optional)
  - Radarr (optional)
  - Sonarr (optional)

## Installation

### Option 1: Download Release (Unsigned)

1. Download `Arrstatus-v*.zip` from [Releases](https://github.com/michalgritzbach/Arrstatus/releases)
2. Unzip the archive
3. **Remove quarantine attribute** (required for unsigned apps):
   ```bash
   xattr -cr Arrstatus.app
   ```
4. Move `Arrstatus.app` to `/Applications`
5. Right-click → "Open" to launch first time

### Option 2: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/michalgritzbach/arrstatus.git
cd arrstatus
```

2. Open the project in Xcode:
```bash
open Arrstatus.xcodeproj
```

3. Build and run:
```bash
xcodebuild -scheme Arrstatus -project Arrstatus.xcodeproj build
```

Or press `Cmd+R` in Xcode to build and run.

## Configuration

### First Launch

On first launch, Arrstatus will show an onboarding screen:

1. Click **"Configure Services"** to open Preferences
2. Enable the services you want to monitor
3. Enter credentials for each enabled service
4. Test each connection before saving
5. (Optional) Adjust polling interval (default: 5 seconds)

### Preferences Window

Access Preferences anytime:
- Click the menubar icon → **"Preferences..."**
- Or press `Cmd+,`

#### Service Configuration

For each service, configure:

**qBittorrent:**
- Base URL: `https://your-server:8080`
- Username: Your qBittorrent username
- Password: Your qBittorrent password (stored in Keychain)
- Web UI URL: (Optional) Different URL for opening in browser

**SABnzbd:**
- Base URL: `https://your-server:8081`
- API Key: Found in SABnzbd Config → General → API Key (stored in Keychain)
- Web UI URL: (Optional) Different URL for opening in browser

**Radarr:**
- Base URL: `https://your-server:7878`
- API Key: Found in Radarr Settings → General → Security (stored in Keychain)
- Web UI URL: (Optional) Different URL for opening in browser

**Sonarr:**
- Base URL: `https://your-server:8989`
- API Key: Found in Sonarr Settings → General → Security (stored in Keychain)
- Web UI URL: (Optional) Different URL for opening in browser

#### Security

- **Passwords and API keys** are stored securely in macOS Keychain
- **Non-sensitive settings** (URLs, enabled state) are stored in UserDefaults
- Credentials never leave your Mac

#### Web UI URL

Leave **Web UI URL** empty to use Base URL when clicking on items. Only set it if:
- You access services through a reverse proxy with different URL
- Your Web UI is on a different port/domain than the API

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
├── Models/
│   ├── Settings/                   # Configuration models
│   │   └── ServiceConfiguration.swift
│   ├── DownloadClient/            # qBittorrent & SABnzbd models
│   ├── ArrService/                # Radarr & Sonarr models
│   └── AggregatedStatus.swift     # Combined status
├── Services/
│   ├── DownloadClients/           # Download client API clients
│   ├── ArrServices/               # *arr service API clients
│   ├── StatusAggregator.swift     # Orchestrator with dynamic clients
│   └── SettingsManager.swift      # Settings coordination (@Observable)
├── Utilities/
│   ├── KeychainManager.swift      # Secure credential storage
│   └── FormatHelpers.swift        # Formatting utilities
├── Views/
│   ├── Settings/                  # Preferences window
│   │   ├── SettingsView.swift
│   │   ├── ServiceConfigurationRow.swift
│   │   └── QBittorrentConfigurationRow.swift
│   ├── MenuBarContentView.swift   # Native menu dropdown
│   ├── MenuBarLabel.swift         # Menubar icon/text
│   └── OnboardingView.swift       # First launch screen
└── Tests/
    └── ArrstatusTests/            # 56 unit tests
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

### "Application is damaged"

This happens with unsigned apps downloaded from the internet. macOS adds a "quarantine" flag that blocks unsigned apps.

**Fix:**

```bash
# Navigate to where you unzipped the app
cd ~/Downloads  # or wherever your app is

# Remove quarantine attribute
xattr -cr Arrstatus.app

# Launch the app
open Arrstatus.app
```

**Why?** This is an unsigned build (no Apple Developer ID signature). macOS Gatekeeper blocks unsigned apps with quarantine attributes. The `xattr -cr` command removes this flag.

### Security Warning on First Launch

Even after removing quarantine, macOS will show a warning on first launch:

1. Right-click (or Control+click) on `Arrstatus.app`
2. Select **"Open"** from the menu
3. Click **"Open"** in the security dialog
4. After first launch, you can open normally

### Connection Issues

- Verify your services are accessible from your Mac
- Check firewall settings
- Ensure API keys are correct
- Test URLs in a browser first
- Use HTTPS URLs when possible

### Authentication Failures

- **qBittorrent**: Check username/password in Web UI settings
- **SABnzbd/Radarr/Sonarr**: Verify API key hasn't been regenerated
- Use **"Test Connection"** button in Preferences to verify

### No Data Showing

- Check Console.app for error logs (filter for "Arrstatus")
- Verify services have active downloads/items in queue
- Ensure polling interval isn't too long (default: 5 seconds)
- Check that services are enabled in Preferences

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
