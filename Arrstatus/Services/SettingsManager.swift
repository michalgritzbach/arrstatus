//
//  SettingsManager.swift
//  Arrstatus
//
//  Reads configuration from ~/.config/arrstatus/arrstatus.conf (INI format).
//  Watches the file for changes and re-emits configurationDidChange.
//

import Foundation
import Combine

// MARK: - Settings Manager

@Observable
class SettingsManager {
    static let shared = SettingsManager()

    private let configPath: URL
    private var lastModificationDate: Date?
    private var watchTimer: Timer?

    private(set) var settings: AppSettings
    let configurationDidChange = PassthroughSubject<Void, Never>()

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configPath = home.appendingPathComponent(".config/arrstatus/arrstatus.conf")
        settings = Self.loadSettings(from: configPath)
        lastModificationDate = Self.modificationDate(of: configPath)
        startWatching()
    }

    // MARK: - File Watching

    private func startWatching() {
        watchTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        let currentDate = Self.modificationDate(of: configPath)
        guard currentDate != lastModificationDate else { return }
        lastModificationDate = currentDate
        let newSettings = Self.loadSettings(from: configPath)
        if newSettings != settings {
            settings = newSettings
            configurationDidChange.send()
        }
    }

    private static func modificationDate(of url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    // MARK: - Parsing

    private static func loadSettings(from url: URL) -> AppSettings {
        if !FileManager.default.fileExists(atPath: url.path) {
            createDefaultConfig(at: url)
        }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("⚠️ Could not read config at \(url.path) — using defaults")
            return .default
        }
        return parseINI(content)
    }

    private static func createDefaultConfig(at url: URL) {
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let content = """
            # arrstatus configuration
            # Edit this file to configure your services.
            # Changes are picked up automatically (no restart required).

            [general]
            poll_interval = 10

            [qbittorrent]
            enabled = false
            url = http://localhost:8080
            webui_url =
            username = admin
            password =

            [sabnzbd]
            enabled = false
            url = http://localhost:8080
            webui_url =
            api_key =

            [radarr]
            enabled = false
            url = http://localhost:7878
            webui_url =
            api_key =

            [sonarr]
            enabled = false
            url = http://localhost:8989
            webui_url =
            api_key =

            [lidarr]
            enabled = false
            url = http://localhost:8686
            webui_url =
            api_key =
            """
        try? content.write(to: url, atomically: true, encoding: .utf8)
        print("📝 Created default config at \(url.path)")
    }

    private static func parseINI(_ content: String) -> AppSettings {
        var sections: [String: [String: String]] = [:]
        var current = ""

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#"), !line.hasPrefix(";") else { continue }

            if line.hasPrefix("[") && line.hasSuffix("]") {
                current = String(line.dropFirst().dropLast()).lowercased()
                sections[current] = [:]
            } else if let eq = line.range(of: "=") {
                let key = line[line.startIndex..<eq.lowerBound].trimmingCharacters(in: .whitespaces).lowercased()
                let value = line[eq.upperBound...].trimmingCharacters(in: .whitespaces)
                sections[current]?[key] = value
            }
        }

        func str(_ sec: String, _ key: String) -> String { sections[sec]?[key] ?? "" }
        func enabled(_ sec: String) -> Bool {
            let v = sections[sec]?["enabled"]?.lowercased()
            return v == "true" || v == "1" || v == "yes"
        }
        func interval() -> TimeInterval { Double(sections["general"]?["poll_interval"] ?? "") ?? 5.0 }

        return AppSettings(
            qbittorrent: QBittorrentConfiguration(
                baseURL: str("qbittorrent", "url"),
                webUIURL: str("qbittorrent", "webui_url"),
                username: str("qbittorrent", "username"),
                password: str("qbittorrent", "password"),
                isEnabled: enabled("qbittorrent")
            ),
            sabnzbd: ServiceConfiguration(
                baseURL: str("sabnzbd", "url"),
                webUIURL: str("sabnzbd", "webui_url"),
                isEnabled: enabled("sabnzbd"),
                apiKey: str("sabnzbd", "api_key")
            ),
            radarr: ServiceConfiguration(
                baseURL: str("radarr", "url"),
                webUIURL: str("radarr", "webui_url"),
                isEnabled: enabled("radarr"),
                apiKey: str("radarr", "api_key")
            ),
            sonarr: ServiceConfiguration(
                baseURL: str("sonarr", "url"),
                webUIURL: str("sonarr", "webui_url"),
                isEnabled: enabled("sonarr"),
                apiKey: str("sonarr", "api_key")
            ),
            lidarr: ServiceConfiguration(
                baseURL: str("lidarr", "url"),
                webUIURL: str("lidarr", "webui_url"),
                isEnabled: enabled("lidarr"),
                apiKey: str("lidarr", "api_key")
            ),
            pollingInterval: interval()
        )
    }

    // MARK: - Convenience

    var hasAnyServiceConfigured: Bool {
        settings.qbittorrent.isEnabled ||
        settings.sabnzbd.isEnabled ||
        settings.radarr.isEnabled ||
        settings.sonarr.isEnabled ||
        settings.lidarr.isEnabled
    }

    var isFirstLaunch: Bool { false }

    // Stub save methods (config is file-based; edit the file directly)
    func saveSettings(_ newSettings: AppSettings) {}
    func saveQBittorrentPassword(_ password: String) throws {}
    func saveSABnzbdAPIKey(_ apiKey: String) throws {}
    func saveRadarrAPIKey(_ apiKey: String) throws {}
    func saveSonarrAPIKey(_ apiKey: String) throws {}

    // Credential accessors (now just reads from parsed settings)
    func getQBittorrentPassword() async -> String? {
        settings.qbittorrent.password.isEmpty ? nil : settings.qbittorrent.password
    }
    func getSABnzbdAPIKey() async -> String? {
        settings.sabnzbd.apiKey.isEmpty ? nil : settings.sabnzbd.apiKey
    }
    func getRadarrAPIKey() async -> String? {
        settings.radarr.apiKey.isEmpty ? nil : settings.radarr.apiKey
    }
    func getSonarrAPIKey() async -> String? {
        settings.sonarr.apiKey.isEmpty ? nil : settings.sonarr.apiKey
    }
    func getLidarrAPIKey() async -> String? {
        settings.lidarr.apiKey.isEmpty ? nil : settings.lidarr.apiKey
    }
}
