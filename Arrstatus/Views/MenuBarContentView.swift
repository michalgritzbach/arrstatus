//
//  MenuBarContentView.swift
//  Arrstatus
//

import SwiftUI

struct MenuBarContentView: View {
    @Environment(StatusAggregator.self) private var aggregator
    @State private var settingsManager = SettingsManager.shared

    var body: some View {
        if !settingsManager.hasAnyServiceConfigured {
            VStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)

                Text("No Services Configured")
                    .font(.headline)

                Text("Edit ~/.config/arrstatus/arrstatus.conf to configure services")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(width: 300)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } else {
            let settings = settingsManager.settings

            // qBittorrent
            if let qb = aggregator.status.qbittorrent {
                let downloadingCount = qb.activeTorrents.filter { $0.dlspeed > 0 }.count
                let uploadingCount = qb.activeTorrents.filter { $0.upspeed > 0 }.count

                Section("qBittorrent") {
                    Button { openURL(settings.qbittorrent.effectiveWebUIURL) } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.green, Color.green.opacity(0.3))
                        Text(FormatHelpers.formatSpeed(qb.transferInfo.dlInfoSpeed))
                        Text("\(downloadingCount) \(downloadingCount == 1 ? "torrent" : "torrents")")
                            .foregroundStyle(.secondary)
                    }
                    Button { openURL(settings.qbittorrent.effectiveWebUIURL) } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.blue, Color.blue.opacity(0.3))
                        Text(FormatHelpers.formatSpeed(qb.transferInfo.upInfoSpeed))
                        Text("\(uploadingCount) \(uploadingCount == 1 ? "torrent" : "torrents")")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // SABnzbd
            if let sab = aggregator.status.sabnzbd {
                let downloadingCount = sab.queue.slots.filter { $0.status.lowercased() == "downloading" }.count

                Section("SABnzbd") {
                    Button { openURL(settings.sabnzbd.effectiveWebUIURL) } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.green, Color.green.opacity(0.3))
                        Text(FormatHelpers.formatSpeed(sab.queue.speedBytesInt))
                        Text("\(downloadingCount) \(downloadingCount == 1 ? "download" : "downloads")")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            let hasArrServices = settings.radarr.isEnabled || settings.sonarr.isEnabled ||
                                 settings.lidarr.isEnabled
            if hasArrServices {
                Divider()
            }

            // Radarr
            if settings.radarr.isEnabled {
                Section("Radarr") {
                    if aggregator.status.radarr.isEmpty {
                        Text("No active items").foregroundStyle(.secondary)
                    } else {
                        ForEach(aggregator.status.radarr) { item in
                            Button {
                                openURL("\(settings.radarr.effectiveWebUIURL)/movie/\(item.movie?.tmdbId ?? item.movieId)")
                            } label: {
                                Text(item.displayTitle)
                                Text(item.displayStatus).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Sonarr
            if settings.sonarr.isEnabled {
                if settings.radarr.isEnabled { Divider() }
                Section("Sonarr") {
                    if aggregator.status.sonarr.isEmpty {
                        Text("No active items").foregroundStyle(.secondary)
                    } else {
                        ForEach(aggregator.status.sonarr) { item in
                            Button {
                                openURL("\(settings.sonarr.effectiveWebUIURL)/series/\(item.series?.id ?? item.seriesId)")
                            } label: {
                                Text(item.displayTitle)
                                Text(item.displayStatus).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Lidarr
            if settings.lidarr.isEnabled {
                if settings.radarr.isEnabled || settings.sonarr.isEnabled { Divider() }
                Section("Lidarr") {
                    if aggregator.status.lidarr.isEmpty {
                        Text("No active items").foregroundStyle(.secondary)
                    } else {
                        ForEach(aggregator.status.lidarr) { item in
                            Button {
                                openURL("\(settings.lidarr.effectiveWebUIURL)/artist/\(item.artistId)")
                            } label: {
                                Text(item.displayTitle)
                                Text(item.displayStatus).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Divider()

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
