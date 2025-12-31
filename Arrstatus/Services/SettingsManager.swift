//
//  SettingsManager.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation
import Combine

// MARK: - Settings Manager

@Observable
class SettingsManager {
    static let shared = SettingsManager()

    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainManager.shared

    // Published settings
    private(set) var settings: AppSettings

    // Configuration change notification
    let configurationDidChange = PassthroughSubject<Void, Never>()

    private init() {
        self.settings = Self.loadSettings()
    }

    // MARK: - Load/Save

    private static func loadSettings() -> AppSettings {
        let defaults = UserDefaults.standard

        return AppSettings(
            qbittorrent: QBittorrentConfiguration(
                baseURL: defaults.string(forKey: "arrstatus.qbittorrent.baseURL") ?? "",
                webUIURL: defaults.string(forKey: "arrstatus.qbittorrent.webUIURL") ?? "",
                username: defaults.string(forKey: "arrstatus.qbittorrent.username") ?? "",
                isEnabled: defaults.bool(forKey: "arrstatus.qbittorrent.enabled")
            ),
            sabnzbd: ServiceConfiguration(
                baseURL: defaults.string(forKey: "arrstatus.sabnzbd.baseURL") ?? "",
                webUIURL: defaults.string(forKey: "arrstatus.sabnzbd.webUIURL") ?? "",
                isEnabled: defaults.bool(forKey: "arrstatus.sabnzbd.enabled")
            ),
            radarr: ServiceConfiguration(
                baseURL: defaults.string(forKey: "arrstatus.radarr.baseURL") ?? "",
                webUIURL: defaults.string(forKey: "arrstatus.radarr.webUIURL") ?? "",
                isEnabled: defaults.bool(forKey: "arrstatus.radarr.enabled")
            ),
            sonarr: ServiceConfiguration(
                baseURL: defaults.string(forKey: "arrstatus.sonarr.baseURL") ?? "",
                webUIURL: defaults.string(forKey: "arrstatus.sonarr.webUIURL") ?? "",
                isEnabled: defaults.bool(forKey: "arrstatus.sonarr.enabled")
            ),
            pollingInterval: defaults.object(forKey: "arrstatus.polling.interval") as? TimeInterval ?? 5.0
        )
    }

    func saveSettings(_ newSettings: AppSettings) {
        self.settings = newSettings

        // Save to UserDefaults
        userDefaults.set(newSettings.qbittorrent.baseURL, forKey: "arrstatus.qbittorrent.baseURL")
        userDefaults.set(newSettings.qbittorrent.webUIURL, forKey: "arrstatus.qbittorrent.webUIURL")
        userDefaults.set(newSettings.qbittorrent.username, forKey: "arrstatus.qbittorrent.username")
        userDefaults.set(newSettings.qbittorrent.isEnabled, forKey: "arrstatus.qbittorrent.enabled")

        userDefaults.set(newSettings.sabnzbd.baseURL, forKey: "arrstatus.sabnzbd.baseURL")
        userDefaults.set(newSettings.sabnzbd.webUIURL, forKey: "arrstatus.sabnzbd.webUIURL")
        userDefaults.set(newSettings.sabnzbd.isEnabled, forKey: "arrstatus.sabnzbd.enabled")

        userDefaults.set(newSettings.radarr.baseURL, forKey: "arrstatus.radarr.baseURL")
        userDefaults.set(newSettings.radarr.webUIURL, forKey: "arrstatus.radarr.webUIURL")
        userDefaults.set(newSettings.radarr.isEnabled, forKey: "arrstatus.radarr.enabled")

        userDefaults.set(newSettings.sonarr.baseURL, forKey: "arrstatus.sonarr.baseURL")
        userDefaults.set(newSettings.sonarr.webUIURL, forKey: "arrstatus.sonarr.webUIURL")
        userDefaults.set(newSettings.sonarr.isEnabled, forKey: "arrstatus.sonarr.enabled")

        userDefaults.set(newSettings.pollingInterval, forKey: "arrstatus.polling.interval")

        configurationDidChange.send()
    }

    // MARK: - Credentials (Keychain)

    func saveQBittorrentPassword(_ password: String) throws {
        try keychain.save(password, for: "qbittorrent.password")
    }

    func getQBittorrentPassword() -> String? {
        try? keychain.retrieve("qbittorrent.password")
    }

    func saveSABnzbdAPIKey(_ apiKey: String) throws {
        try keychain.save(apiKey, for: "sabnzbd.apikey")
    }

    func getSABnzbdAPIKey() -> String? {
        try? keychain.retrieve("sabnzbd.apikey")
    }

    func saveRadarrAPIKey(_ apiKey: String) throws {
        try keychain.save(apiKey, for: "radarr.apikey")
    }

    func getRadarrAPIKey() -> String? {
        try? keychain.retrieve("radarr.apikey")
    }

    func saveSonarrAPIKey(_ apiKey: String) throws {
        try keychain.save(apiKey, for: "sonarr.apikey")
    }

    func getSonarrAPIKey() -> String? {
        try? keychain.retrieve("sonarr.apikey")
    }

    // MARK: - First Launch

    var isFirstLaunch: Bool {
        get { !userDefaults.bool(forKey: "arrstatus.firstLaunch.completed") }
        set { userDefaults.set(!newValue, forKey: "arrstatus.firstLaunch.completed") }
    }

    var hasAnyServiceConfigured: Bool {
        settings.qbittorrent.isEnabled ||
        settings.sabnzbd.isEnabled ||
        settings.radarr.isEnabled ||
        settings.sonarr.isEnabled
    }
}
