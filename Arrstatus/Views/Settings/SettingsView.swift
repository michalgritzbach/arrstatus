//
//  SettingsView.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var settingsManager = SettingsManager.shared
    @State private var settings: AppSettings

    // Credentials (not stored in settings model)
    @State private var qbPassword: String = ""
    @State private var sabAPIKey: String = ""
    @State private var radarrAPIKey: String = ""
    @State private var sonarrAPIKey: String = ""

    init() {
        let manager = SettingsManager.shared
        _settings = State(initialValue: manager.settings)
    }

    var body: some View {
        Form {
            Section("Download Clients") {
                QBittorrentConfigurationRow(
                    isEnabled: $settings.qbittorrent.isEnabled,
                    baseURL: $settings.qbittorrent.baseURL,
                    webUIURL: $settings.qbittorrent.webUIURL,
                    username: $settings.qbittorrent.username,
                    password: $qbPassword,
                    onTestConnection: testQBittorrentConnection
                )

                ServiceConfigurationRow(
                    serviceName: "SABnzbd",
                    iconName: "arrow.down.circle.fill",
                    isEnabled: $settings.sabnzbd.isEnabled,
                    baseURL: $settings.sabnzbd.baseURL,
                    webUIURL: $settings.sabnzbd.webUIURL,
                    credential: $sabAPIKey,
                    credentialLabel: "API Key",
                    onTestConnection: testSABnzbdConnection
                )
            }

            Section("Media Management") {
                ServiceConfigurationRow(
                    serviceName: "Radarr",
                    iconName: "film",
                    isEnabled: $settings.radarr.isEnabled,
                    baseURL: $settings.radarr.baseURL,
                    webUIURL: $settings.radarr.webUIURL,
                    credential: $radarrAPIKey,
                    credentialLabel: "API Key",
                    onTestConnection: testRadarrConnection
                )

                ServiceConfigurationRow(
                    serviceName: "Sonarr",
                    iconName: "tv",
                    isEnabled: $settings.sonarr.isEnabled,
                    baseURL: $settings.sonarr.baseURL,
                    webUIURL: $settings.sonarr.webUIURL,
                    credential: $sonarrAPIKey,
                    credentialLabel: "API Key",
                    onTestConnection: testSonarrConnection
                )
            }

            Section("General") {
                LabeledContent("Polling Interval") {
                    HStack {
                        Slider(value: $settings.pollingInterval, in: 5...60, step: 5)
                            .frame(width: 200)
                        Text("\(Int(settings.pollingInterval)) seconds")
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 600, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSettings()
                }
            }
        }
        .task {
            // Load credentials from keychain asynchronously
            qbPassword = await settingsManager.getQBittorrentPassword() ?? ""
            sabAPIKey = await settingsManager.getSABnzbdAPIKey() ?? ""
            radarrAPIKey = await settingsManager.getRadarrAPIKey() ?? ""
            sonarrAPIKey = await settingsManager.getSonarrAPIKey() ?? ""
        }
    }

    private func saveSettings() {
        // Save to SettingsManager
        settingsManager.saveSettings(settings)

        // Save credentials to keychain
        if !qbPassword.isEmpty {
            try? settingsManager.saveQBittorrentPassword(qbPassword)
        }
        if !sabAPIKey.isEmpty {
            try? settingsManager.saveSABnzbdAPIKey(sabAPIKey)
        }
        if !radarrAPIKey.isEmpty {
            try? settingsManager.saveRadarrAPIKey(radarrAPIKey)
        }
        if !sonarrAPIKey.isEmpty {
            try? settingsManager.saveSonarrAPIKey(sonarrAPIKey)
        }
    }

    // MARK: - Connection Testing

    private func testQBittorrentConnection() async -> Result<Void, Error> {
        guard !settings.qbittorrent.baseURL.isEmpty, !qbPassword.isEmpty else {
            return .failure(TestError.missingConfiguration)
        }

        let client = QBittorrentClient(
            baseURL: settings.qbittorrent.baseURL,
            username: settings.qbittorrent.username,
            password: qbPassword
        )

        do {
            // Test authentication without storing session
            try await client.testConnection()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func testSABnzbdConnection() async -> Result<Void, Error> {
        guard !settings.sabnzbd.baseURL.isEmpty, !sabAPIKey.isEmpty else {
            return .failure(TestError.missingConfiguration)
        }

        let client = SABnzbdClient(
            baseURL: settings.sabnzbd.baseURL,
            apiKey: sabAPIKey
        )

        do {
            _ = try await client.fetchStatus()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func testRadarrConnection() async -> Result<Void, Error> {
        guard !settings.radarr.baseURL.isEmpty, !radarrAPIKey.isEmpty else {
            return .failure(TestError.missingConfiguration)
        }

        let client = RadarrClient(
            baseURL: settings.radarr.baseURL,
            apiKey: radarrAPIKey
        )

        do {
            _ = try await client.getQueue()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func testSonarrConnection() async -> Result<Void, Error> {
        guard !settings.sonarr.baseURL.isEmpty, !sonarrAPIKey.isEmpty else {
            return .failure(TestError.missingConfiguration)
        }

        let client = SonarrClient(
            baseURL: settings.sonarr.baseURL,
            apiKey: sonarrAPIKey
        )

        do {
            _ = try await client.getQueue()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Test Error

enum TestError: LocalizedError {
    case missingConfiguration

    var errorDescription: String? {
        "Please fill in all required fields"
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
