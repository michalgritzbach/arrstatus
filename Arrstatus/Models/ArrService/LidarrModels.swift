//
//  LidarrModels.swift
//  Arrstatus
//

import Foundation

// MARK: - Artist Object

struct LidarrArtist: Codable {
    let id: Int
    let artistName: String
}

// MARK: - Album Object

struct LidarrAlbum: Codable {
    let id: Int
    let title: String
    let releaseDate: String? = nil
}

// MARK: - Queue Item

struct LidarrQueueItem: Codable, Identifiable {
    let id: Int
    let artistId: Int
    let albumId: Int?
    let title: String
    let status: String
    let trackedDownloadStatus: String?
    let trackedDownloadState: String?
    let size: Double?
    let sizeleft: Double?
    let timeleft: String?
    let artist: LidarrArtist?
    let album: LidarrAlbum?

    var displayTitle: String {
        if let artist = artist, let album = album {
            var label = "\(artist.artistName) – \(album.title)"
            if let year = album.releaseDate?.prefix(4), !year.isEmpty {
                label += " (\(year))"
            }
            return label
        }
        return album?.title ?? artist?.artistName ?? title
    }

    var displayStatus: String {
        var statusText = ""

        if let state = trackedDownloadState?.lowercased() {
            switch state {
            case "downloading":
                statusText = "Downloading"
            case "importpending":
                statusText = "Importing"
            default:
                statusText = status.capitalized
            }
        } else if trackedDownloadStatus?.lowercased() == "warning" {
            statusText = "Stalled"
        } else {
            statusText = status.capitalized
        }

        if trackedDownloadState?.lowercased() == "downloading" {
            var details: [String] = []

            if let total = size, let left = sizeleft, total > 0 {
                let progress = Int((total - left) / total * 100)
                details.append("\(progress)%")
            }

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
        guard let state = trackedDownloadState?.lowercased() else { return false }
        return state == "downloading" ||
               state == "importpending" ||
               trackedDownloadStatus?.lowercased() == "warning"
    }

    private func formatTimeLeft(_ timeString: String) -> String {
        let components = timeString.split(separator: ".")
        if components.count == 2, let days = Int(components[0]) {
            let timeComponents = components[1].split(separator: ":")
            if timeComponents.count >= 2, let hours = Int(timeComponents[0]) {
                if days > 0 { return "\(days)d \(hours)h" }
                if hours > 0 { return "\(hours)h" }
            }
        } else {
            let timeComponents = timeString.split(separator: ":")
            if timeComponents.count >= 2,
               let hours = Int(timeComponents[0]),
               let minutes = Int(timeComponents[1]) {
                if hours > 0 { return "\(hours)h \(minutes)m" }
                if minutes > 0 { return "\(minutes)m" }
            }
        }
        return timeString
    }
}
