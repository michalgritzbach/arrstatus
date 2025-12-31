//
//  MenuBarContentView.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

struct MenuBarContentView: View {
    @Environment(StatusAggregator.self) private var aggregator

    var body: some View {
        // Download Clients Section
        if let qb = aggregator.status.qbittorrent {
            let downloadingCount = qb.activeTorrents.filter { $0.dlspeed > 0 }.count
            let uploadingCount = qb.activeTorrents.filter { $0.upspeed > 0 }.count

            Section("qBittorrent") {
                Button {
                    openURL(AppConfiguration.QBittorrent.webUIURL)
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.green, Color.green.opacity(0.3))
                    Text(FormatHelpers.formatSpeed(qb.transferInfo.dlInfoSpeed))
                    Text("\(downloadingCount) \(downloadingCount == 1 ? "torrent" : "torrents")")
                        .foregroundStyle(.secondary)
                }
                Button {
                    openURL(AppConfiguration.QBittorrent.webUIURL)
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
                    openURL(AppConfiguration.SABnzbd.webUIURL)
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

        Divider()

        // Radarr Section
        Section("Radarr") {
            if aggregator.status.radarr.isEmpty {
                Text("No active items")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(aggregator.status.radarr) { item in
                    Button {
                        openURL("\(AppConfiguration.Radarr.webUIURL)/movie/\(item.movie?.tmdbId ?? item.movieId)")
                    } label: {
                        Text(item.displayTitle)
                        Text(item.displayStatus)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }

        Divider()

        // Sonarr Section
        Section("Sonarr") {
            if aggregator.status.sonarr.isEmpty {
                Text("No active items")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(aggregator.status.sonarr) { item in
                    Button {
                        openURL("\(AppConfiguration.Sonarr.webUIURL)/series/\(item.series?.id ?? item.seriesId)")
                    } label: {
                        Text(item.displayTitle)
                        Text(item.displayStatus)
                            .foregroundStyle(.secondary)
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
