//
//  SonarrModels.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

// MARK: - Series Object
struct SonarrSeries: Codable {
    let id: Int
    let title: String
}

// MARK: - Episode Object
struct SonarrEpisode: Codable {
    let seasonNumber: Int?
    let episodeNumber: Int?
    let title: String? = nil
}

// MARK: - Queue Item
struct SonarrQueueItem: Codable, Identifiable {
    let id: Int
    let seriesId: Int
    let episodeId: Int?
    let title: String
    let status: String
    let trackedDownloadStatus: String?
    let trackedDownloadState: String?
    let size: Double?
    let sizeleft: Double?
    let timeleft: String?
    let series: SonarrSeries?
    let episode: SonarrEpisode?

    var displayTitle: String {
        if let seriesTitle = series?.title, let episode = episode {
            if let season = episode.seasonNumber, let ep = episode.episodeNumber {
                var label = "\(seriesTitle)  S\(String(format: "%02d", season))E\(String(format: "%02d", ep))"
                if let epTitle = episode.title, !epTitle.isEmpty {
                    label += "  \(epTitle)"
                }
                return label
            }
            return seriesTitle
        }
        return title
    }

    var displayStatus: String {
        var statusText = ""

        // Determine basic status
        if let state = trackedDownloadState?.lowercased() {
            switch state {
            case "downloading":
                statusText = "Downloading"
            case "importpending":
                statusText = "Importing"
            default:
                statusText = status.capitalized
            }
        } else if let dlStatus = trackedDownloadStatus?.lowercased(), dlStatus == "warning" {
            statusText = "Stalled"
        } else {
            statusText = status.capitalized
        }

        // Add progress info if downloading
        if let state = trackedDownloadState?.lowercased(), state == "downloading" {
            var details: [String] = []

            // Add percentage if we have size info
            if let total = size, let left = sizeleft, total > 0 {
                let progress = Int((total - left) / total * 100)
                details.append("\(progress)%")
            }

            // Add ETA if available
            if let eta = timeleft, !eta.isEmpty {
                details.append(formatTimeLeft(eta))
            }

            if !details.isEmpty {
                statusText += " · " + details.joined(separator: " · ")
            }
        }

        return statusText
    }

    var isActive: Bool {
        // Consider item active if downloading, importing, or has warnings
        guard let state = trackedDownloadState?.lowercased() else {
            return false
        }

        return state == "downloading" ||
               state == "importpending" ||
               trackedDownloadStatus?.lowercased() == "warning"
    }

    private func formatTimeLeft(_ timeString: String) -> String {
        // Parse format like "63.06:58:33" (days.hours:minutes:seconds)
        let components = timeString.split(separator: ".")

        if components.count == 2 {
            // Has days
            if let days = Int(components[0]) {
                let timeComponents = components[1].split(separator: ":")
                if timeComponents.count >= 2, let hours = Int(timeComponents[0]) {
                    if days > 0 {
                        return "\(days)d \(hours)h"
                    } else if hours > 0 {
                        return "\(hours)h"
                    }
                }
            }
        } else {
            // No days, just hours:minutes:seconds
            let timeComponents = timeString.split(separator: ":")
            if timeComponents.count >= 2 {
                if let hours = Int(timeComponents[0]), let minutes = Int(timeComponents[1]) {
                    if hours > 0 {
                        return "\(hours)h \(minutes)m"
                    } else if minutes > 0 {
                        return "\(minutes)m"
                    }
                }
            }
        }

        return timeString // Fallback to original
    }
}
