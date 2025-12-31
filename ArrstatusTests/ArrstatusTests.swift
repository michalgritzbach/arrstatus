//
//  ArrstatusTests.swift
//  ArrstatusTests
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation
import Testing
@testable import Arrstatus

// MARK: - FormatHelpers Tests
struct FormatHelpersTests {

    @Test func formatSpeedBytes() {
        #expect(FormatHelpers.formatSpeed(500) == "500 B/s")
    }

    @Test func formatSpeedKilobytes() {
        #expect(FormatHelpers.formatSpeed(5120) == "5.0 KB/s")
        #expect(FormatHelpers.formatSpeed(102400) == "100.0 KB/s")
    }

    @Test func formatSpeedMegabytes() {
        #expect(FormatHelpers.formatSpeed(5_242_880) == "5.00 MB/s")
        #expect(FormatHelpers.formatSpeed(104_857_600) == "100.00 MB/s")
    }

    @Test func formatSpeedGigabytes() {
        #expect(FormatHelpers.formatSpeed(1_073_741_824) == "1.00 GB/s")
        #expect(FormatHelpers.formatSpeed(5_368_709_120) == "5.00 GB/s")
    }

    @Test func formatSpeedZero() {
        #expect(FormatHelpers.formatSpeed(0) == "0 B/s")
    }

    @Test func formatBytesBytes() {
        #expect(FormatHelpers.formatBytes(512) == "512 B")
    }

    @Test func formatBytesKilobytes() {
        #expect(FormatHelpers.formatBytes(5120) == "5.0 KB")
        #expect(FormatHelpers.formatBytes(1024) == "1.0 KB")
    }

    @Test func formatBytesMegabytes() {
        #expect(FormatHelpers.formatBytes(5_242_880) == "5.00 MB")
        #expect(FormatHelpers.formatBytes(104_857_600) == "100.00 MB")
    }

    @Test func formatBytesGigabytes() {
        #expect(FormatHelpers.formatBytes(1_073_741_824) == "1.00 GB")
        #expect(FormatHelpers.formatBytes(10_737_418_240) == "10.00 GB")
    }

    @Test func formatBytesTerabytes() {
        #expect(FormatHelpers.formatBytes(1_099_511_627_776) == "1.00 TB")
        #expect(FormatHelpers.formatBytes(5_497_558_138_880) == "5.00 TB")
    }
}

// MARK: - RadarrModels Tests
struct RadarrModelsTests {

    @Test func displayTitleWithMovie() {
        let movie = RadarrMovie(id: 1, title: "The Matrix", tmdbId: 603)
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "The.Matrix.1999.1080p.BluRay",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "01:30:00",
            movie: movie
        )
        #expect(item.displayTitle == "The Matrix")
    }

    @Test func displayTitleFallbackToFilename() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "The.Matrix.1999.1080p.BluRay",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "01:30:00",
            movie: nil
        )
        #expect(item.displayTitle == "The.Matrix.1999.1080p.BluRay")
    }

    @Test func displayStatusDownloading() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "01:30:00",
            movie: nil
        )
        #expect(item.displayStatus.contains("Downloading"))
        #expect(item.displayStatus.contains("50%"))
        #expect(item.displayStatus.contains("1h 30m"))
    }

    @Test func displayStatusImporting() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "importPending",
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            movie: nil
        )
        #expect(item.displayStatus == "Importing")
    }

    @Test func displayStatusStalled() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: "warning",
            trackedDownloadState: nil,
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            movie: nil
        )
        #expect(item.displayStatus == "Stalled")
    }

    @Test func isActiveDownloading() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            movie: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isActiveImporting() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "importPending",
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            movie: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isActiveWarning() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: "warning",
            trackedDownloadState: "downloading",
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            movie: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isNotActive() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "completed",
            trackedDownloadStatus: nil,
            trackedDownloadState: nil,
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            movie: nil
        )
        #expect(item.isActive == false)
    }

    @Test func formatTimeLeftWithDays() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "63.06:58:33",
            movie: nil
        )
        #expect(item.displayStatus.contains("63d 6h"))
    }

    @Test func formatTimeLeftHoursOnly() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "02:30:15",
            movie: nil
        )
        #expect(item.displayStatus.contains("2h 30m"))
    }

    @Test func formatTimeLeftMinutesOnly() {
        let item = RadarrQueueItem(
            id: 1,
            movieId: 1,
            title: "Movie",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "00:45:30",
            movie: nil
        )
        #expect(item.displayStatus.contains("45m"))
    }
}

// MARK: - SonarrModels Tests
struct SonarrModelsTests {

    @Test func displayTitleWithSeriesAndEpisode() {
        let series = SonarrSeries(id: 1, title: "Breaking Bad")
        let episode = SonarrEpisode(seasonNumber: 1, episodeNumber: 5)
        let item = SonarrQueueItem(
            id: 1,
            seriesId: 1,
            episodeId: 100,
            title: "Breaking.Bad.S01E05.1080p",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "01:30:00",
            series: series,
            episode: episode
        )
        #expect(item.displayTitle == "Breaking Bad S01E05")
    }

    @Test func displayTitleWithSeriesNoEpisode() {
        let series = SonarrSeries(id: 1, title: "Breaking Bad")
        let item = SonarrQueueItem(
            id: 1,
            seriesId: 1,
            episodeId: nil,
            title: "Breaking.Bad.S01E05.1080p",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "01:30:00",
            series: series,
            episode: nil
        )
        // Without episode object, it falls back to title
        #expect(item.displayTitle == "Breaking.Bad.S01E05.1080p")
    }

    @Test func displayTitleFallbackToFilename() {
        let item = SonarrQueueItem(
            id: 1,
            seriesId: 1,
            episodeId: nil,
            title: "Breaking.Bad.S01E05.1080p",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000,
            sizeleft: 500000,
            timeleft: "01:30:00",
            series: nil,
            episode: nil
        )
        #expect(item.displayTitle == "Breaking.Bad.S01E05.1080p")
    }

    @Test func displayStatusDownloadingWithProgress() {
        let item = SonarrQueueItem(
            id: 1,
            seriesId: 1,
            episodeId: nil,
            title: "Show",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 2000000,
            sizeleft: 500000,
            timeleft: "00:45:00",
            series: nil,
            episode: nil
        )
        #expect(item.displayStatus.contains("Downloading"))
        #expect(item.displayStatus.contains("75%"))
        #expect(item.displayStatus.contains("45m"))
    }

    @Test func isActiveDownloading() {
        let item = SonarrQueueItem(
            id: 1,
            seriesId: 1,
            episodeId: nil,
            title: "Show",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            series: nil,
            episode: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isActiveImportPending() {
        let item = SonarrQueueItem(
            id: 1,
            seriesId: 1,
            episodeId: nil,
            title: "Show",
            status: "downloading",
            trackedDownloadStatus: nil,
            trackedDownloadState: "importPending",
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            series: nil,
            episode: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isNotActive() {
        let item = SonarrQueueItem(
            id: 1,
            seriesId: 1,
            episodeId: nil,
            title: "Show",
            status: "completed",
            trackedDownloadStatus: nil,
            trackedDownloadState: nil,
            size: nil,
            sizeleft: nil,
            timeleft: nil,
            series: nil,
            episode: nil
        )
        #expect(item.isActive == false)
    }
}

// MARK: - QBittorrentModels Tests
struct QBittorrentModelsTests {

    @Test func transferInfoDecoding() throws {
        let json = """
        {
            "dl_info_speed": 5242880,
            "up_info_speed": 1048576
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let transferInfo = try decoder.decode(QBTransferInfo.self, from: data)

        #expect(transferInfo.dlInfoSpeed == 5_242_880)
        #expect(transferInfo.upInfoSpeed == 1_048_576)
    }

    @Test func torrentInfoID() {
        let torrent = QBTorrentInfo(
            hash: "abc123",
            name: "ubuntu.iso",
            dlspeed: 1000000,
            upspeed: 500000,
            state: "downloading"
        )
        #expect(torrent.id == "abc123")
    }

    @Test func clientStatusProperties() {
        let transferInfo = QBTransferInfo(dlInfoSpeed: 5_000_000, upInfoSpeed: 1_000_000)
        let torrents = [
            QBTorrentInfo(hash: "1", name: "file1", dlspeed: 1000, upspeed: 500, state: "downloading"),
            QBTorrentInfo(hash: "2", name: "file2", dlspeed: 2000, upspeed: 1000, state: "seeding")
        ]
        let status = QBClientStatus(transferInfo: transferInfo, activeTorrents: torrents)

        #expect(status.transferInfo.dlInfoSpeed == 5_000_000)
        #expect(status.activeTorrents.count == 2)
    }
}

// MARK: - SABnzbdModels Tests
struct SABnzbdModelsTests {

    @Test func queueSpeedConversion() {
        let queue = SABQueue(speed: "5.2 M", speedBytes: "5120", slots: [])
        #expect(queue.speedBytesInt == 5_242_880)
    }

    @Test func queueSpeedConversionZero() {
        let queue = SABQueue(speed: "0", speedBytes: "0", slots: [])
        #expect(queue.speedBytesInt == 0)
    }

    @Test func slotID() {
        let slot = SABSlot(nzoId: "SABnzbd_nzo_abc123", filename: "ubuntu.iso", mb: "4500", status: "Downloading")
        #expect(slot.id == "SABnzbd_nzo_abc123")
    }

    @Test func queueResponseDecoding() throws {
        let json = """
        {
            "queue": {
                "speed": "5.2 M",
                "kbpersec": "5120",
                "slots": [
                    {
                        "nzo_id": "test123",
                        "filename": "test.nzb",
                        "mb": "1000",
                        "status": "Downloading"
                    }
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SABQueueResponse.self, from: data)

        #expect(response.queue.speed == "5.2 M")
        #expect(response.queue.slots.count == 1)
        #expect(response.queue.slots[0].filename == "test.nzb")
    }
}

// MARK: - AggregatedStatus Tests
struct AggregatedStatusTests {

    @Test func updateWithAllSuccess() {
        var status = AggregatedStatus()

        let qbTransfer = QBTransferInfo(dlInfoSpeed: 5_000_000, upInfoSpeed: 1_000_000)
        let qbTorrents = [
            QBTorrentInfo(hash: "1", name: "file1", dlspeed: 1000, upspeed: 0, state: "downloading"),
            QBTorrentInfo(hash: "2", name: "file2", dlspeed: 0, upspeed: 500, state: "seeding")
        ]
        let qbStatus = QBClientStatus(transferInfo: qbTransfer, activeTorrents: qbTorrents)

        let sabQueue = SABQueue(speed: "2.0 M", speedBytes: "2048", slots: [
            SABSlot(nzoId: "1", filename: "nzb1", mb: "1000", status: "Downloading"),
            SABSlot(nzoId: "2", filename: "nzb2", mb: "500", status: "Paused")
        ])
        let sabStatus = SABClientStatus(queue: sabQueue)

        let radarrItems = [
            RadarrQueueItem(id: 1, movieId: 1, title: "Movie", status: "downloading",
                          trackedDownloadStatus: nil, trackedDownloadState: "downloading",
                          size: nil, sizeleft: nil, timeleft: nil, movie: nil)
        ]

        let sonarrItems = [
            SonarrQueueItem(id: 1, seriesId: 1, episodeId: nil, title: "Show", status: "downloading",
                          trackedDownloadStatus: nil, trackedDownloadState: "downloading",
                          size: nil, sizeleft: nil, timeleft: nil, series: nil, episode: nil)
        ]

        status.update(
            qbStatus: .success(qbStatus),
            sabStatus: .success(sabStatus),
            radarrItems: .success(radarrItems),
            sonarrItems: .success(sonarrItems)
        )

        // 1 downloading torrent + 1 downloading SAB slot + 1 radarr + 1 sonarr = 4
        #expect(status.totalActiveDownloads == 4)

        // 5,000,000 bytes/s (qb) + 2,097,152 bytes/s (sab from 2048 KB/s) = 7,097,152 bytes/s
        #expect(status.totalDownloadSpeed == 7_097_152)

        // 1MB/s from qBittorrent
        #expect(status.totalUploadSpeed == 1_000_000)

        #expect(status.errors.isEmpty)
        #expect(status.qbittorrent != nil)
        #expect(status.sabnzbd != nil)
        #expect(status.radarr.count == 1)
        #expect(status.sonarr.count == 1)
    }

    @Test func updateWithErrors() {
        var status = AggregatedStatus()

        enum TestError: Error {
            case qbError
            case sabError
        }

        status.update(
            qbStatus: .failure(TestError.qbError),
            sabStatus: .failure(TestError.sabError),
            radarrItems: .success([]),
            sonarrItems: .success([])
        )

        #expect(status.totalActiveDownloads == 0)
        #expect(status.totalDownloadSpeed == 0)
        #expect(status.errors.count == 2)
        #expect(status.errors["qbittorrent"] != nil)
        #expect(status.errors["sabnzbd"] != nil)
        #expect(status.qbittorrent == nil)
        #expect(status.sabnzbd == nil)
    }

    @Test func updateFiltersInactiveItems() {
        var status = AggregatedStatus()

        let radarrItems = [
            RadarrQueueItem(id: 1, movieId: 1, title: "Active", status: "downloading",
                          trackedDownloadStatus: nil, trackedDownloadState: "downloading",
                          size: nil, sizeleft: nil, timeleft: nil, movie: nil),
            RadarrQueueItem(id: 2, movieId: 2, title: "Inactive", status: "completed",
                          trackedDownloadStatus: nil, trackedDownloadState: nil,
                          size: nil, sizeleft: nil, timeleft: nil, movie: nil)
        ]

        let sonarrItems = [
            SonarrQueueItem(id: 1, seriesId: 1, episodeId: nil, title: "Active", status: "downloading",
                          trackedDownloadStatus: nil, trackedDownloadState: "downloading",
                          size: nil, sizeleft: nil, timeleft: nil, series: nil, episode: nil),
            SonarrQueueItem(id: 2, seriesId: 2, episodeId: nil, title: "Inactive", status: "completed",
                          trackedDownloadStatus: nil, trackedDownloadState: nil,
                          size: nil, sizeleft: nil, timeleft: nil, series: nil, episode: nil)
        ]

        let qbTransfer = QBTransferInfo(dlInfoSpeed: 0, upInfoSpeed: 0)
        let qbStatus = QBClientStatus(transferInfo: qbTransfer, activeTorrents: [])
        let sabQueue = SABQueue(speed: "0", speedBytes: "0", slots: [])
        let sabStatus = SABClientStatus(queue: sabQueue)

        status.update(
            qbStatus: .success(qbStatus),
            sabStatus: .success(sabStatus),
            radarrItems: .success(radarrItems),
            sonarrItems: .success(sonarrItems)
        )

        // Only active items should be included
        #expect(status.radarr.count == 1)
        #expect(status.sonarr.count == 1)
        #expect(status.totalActiveDownloads == 2)
    }
}
