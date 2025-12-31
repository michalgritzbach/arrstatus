//
//  MenuBarContentView.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

struct MenuBarContentView: View {
    @Environment(StatusAggregator.self) private var aggregator
    @Environment(\.openSettings) private var openSettings
    @State private var settingsManager = SettingsManager.shared

    var body: some View {
        if !settingsManager.hasAnyServiceConfigured {
            // Empty state - no services configured
            VStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)

                Text("No Services Configured")
                    .font(.headline)

                Text("Configure download clients and media services in Preferences")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Preferences") {
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(width: 280)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } else {
            // Normal content with configured services

            // Download Clients Section
            if let qb = aggregator.status.qbittorrent {
                let downloadingCount = qb.activeTorrents.filter { $0.dlspeed > 0 }.count
                let uploadingCount = qb.activeTorrents.filter { $0.upspeed > 0 }.count

                Section("qBittorrent") {
                    Button {
                        let url = settingsManager.settings.qbittorrent.webUIURL.isEmpty
                            ? settingsManager.settings.qbittorrent.baseURL
                            : settingsManager.settings.qbittorrent.webUIURL
                        openURL(url)
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.green, Color.green.opacity(0.3))
                        Text(FormatHelpers.formatSpeed(qb.transferInfo.dlInfoSpeed))
                        Text("\(downloadingCount) \(downloadingCount == 1 ? "torrent" : "torrents")")
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        let url = settingsManager.settings.qbittorrent.webUIURL.isEmpty
                            ? settingsManager.settings.qbittorrent.baseURL
                            : settingsManager.settings.qbittorrent.webUIURL
                        openURL(url)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.blue, Color.blue.opacity(0.3))
                        Text(FormatHelpers.formatSpeed(qb.transferInfo.upInfoSpeed))
                        Text("\(uploadingCount) \(uploadingCount == 1 ? "torrent" : "torrents")")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let sab = aggregator.status.sabnzbd {
                let downloadingCount = sab.queue.slots.filter { $0.status.lowercased() == "downloading" }.count

                Section("SABnzbd") {
                    Button {
                        let url = settingsManager.settings.sabnzbd.webUIURL.isEmpty
                            ? settingsManager.settings.sabnzbd.baseURL
                            : settingsManager.settings.sabnzbd.webUIURL
                        openURL(url)
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.green, Color.green.opacity(0.3))
                        Text(FormatHelpers.formatSpeed(sab.queue.speedBytesInt))
                        Text("\(downloadingCount) \(downloadingCount == 1 ? "download" : "downloads")")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Only show *arr sections if enabled
            if settingsManager.settings.radarr.isEnabled || settingsManager.settings.sonarr.isEnabled {
                Divider()
            }

            // Radarr Section
            if settingsManager.settings.radarr.isEnabled {
                Section("Radarr") {
                    if aggregator.status.radarr.isEmpty {
                        Text("No active items")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(aggregator.status.radarr) { item in
                            Button {
                                let baseURL = settingsManager.settings.radarr.webUIURL.isEmpty
                                    ? settingsManager.settings.radarr.baseURL
                                    : settingsManager.settings.radarr.webUIURL
                                openURL("\(baseURL)/movie/\(item.movie?.tmdbId ?? item.movieId)")
                            } label: {
                                Text(item.displayTitle)
                                Text(item.displayStatus)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Sonarr Section
            if settingsManager.settings.sonarr.isEnabled {
                if settingsManager.settings.radarr.isEnabled {
                    Divider()
                }

                Section("Sonarr") {
                    if aggregator.status.sonarr.isEmpty {
                        Text("No active items")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(aggregator.status.sonarr) { item in
                            Button {
                                let baseURL = settingsManager.settings.sonarr.webUIURL.isEmpty
                                    ? settingsManager.settings.sonarr.baseURL
                                    : settingsManager.settings.sonarr.webUIURL
                                openURL("\(baseURL)/series/\(item.series?.id ?? item.seriesId)")
                            } label: {
                                Text(item.displayTitle)
                                Text(item.displayStatus)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Divider()

            Button("Preferences...") {
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    MenuBarContentView()
        .environment(StatusAggregator())
}
