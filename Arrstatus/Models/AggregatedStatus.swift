//
//  AggregatedStatus.swift
//  Arrstatus
//

import Foundation

// MARK: - Aggregated Status
struct AggregatedStatus {
    var totalActiveDownloads: Int = 0
    var totalDownloadSpeed: Int64 = 0
    var totalUploadSpeed: Int64 = 0

    var qbittorrent: QBClientStatus?
    var sabnzbd: SABClientStatus?
    var radarr: [RadarrQueueItem] = []
    var sonarr: [SonarrQueueItem] = []
    var lidarr: [LidarrQueueItem] = []

    var lastUpdated: Date = .distantPast
    var errors: [String: Error] = [:]

    mutating func update(
        qbStatus: Result<QBClientStatus, Error>,
        sabStatus: Result<SABClientStatus, Error>,
        radarrItems: Result<[RadarrQueueItem], Error>,
        sonarrItems: Result<[SonarrQueueItem], Error>,
        lidarrItems: Result<[LidarrQueueItem], Error> = .success([])
    ) {
        errors.removeAll()
        totalActiveDownloads = 0
        totalDownloadSpeed = 0
        totalUploadSpeed = 0

        switch qbStatus {
        case .success(let status):
            qbittorrent = status
            totalDownloadSpeed += status.transferInfo.dlInfoSpeed
            totalUploadSpeed += status.transferInfo.upInfoSpeed
            totalActiveDownloads += status.activeTorrents.filter { $0.dlspeed > 0 }.count
        case .failure(let error):
            errors["qbittorrent"] = error
            qbittorrent = nil
        }

        switch sabStatus {
        case .success(let status):
            sabnzbd = status
            totalDownloadSpeed += status.queue.speedBytesInt
            totalActiveDownloads += status.queue.slots.filter { $0.status.lowercased() == "downloading" }.count
        case .failure(let error):
            errors["sabnzbd"] = error
            sabnzbd = nil
        }

        switch radarrItems {
        case .success(let items):
            radarr = items.filter { $0.isActive }
            totalActiveDownloads += radarr.count
        case .failure(let error):
            errors["radarr"] = error
            radarr = []
        }

        switch sonarrItems {
        case .success(let items):
            sonarr = items.filter { $0.isActive }
            totalActiveDownloads += sonarr.count
        case .failure(let error):
            errors["sonarr"] = error
            sonarr = []
        }

        switch lidarrItems {
        case .success(let items):
            lidarr = items.filter { $0.isActive }
            totalActiveDownloads += lidarr.count
        case .failure(let error):
            errors["lidarr"] = error
            lidarr = []
        }

        lastUpdated = Date()
    }
}
