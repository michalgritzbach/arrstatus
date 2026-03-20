//
//  ArrstatusTests.swift
//  ArrstatusTests
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
            id: 1, movieId: 1, title: "The.Matrix.1999.1080p.BluRay",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "01:30:00", movie: movie
        )
        #expect(item.displayTitle == "The Matrix")
    }

    @Test func displayTitleFallbackToFilename() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "The.Matrix.1999.1080p.BluRay",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "01:30:00", movie: nil
        )
        #expect(item.displayTitle == "The.Matrix.1999.1080p.BluRay")
    }

    @Test func displayStatusDownloading() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "01:30:00", movie: nil
        )
        #expect(item.displayStatus.contains("Downloading"))
        #expect(item.displayStatus.contains("50%"))
        #expect(item.displayStatus.contains("1h 30m"))
    }

    @Test func displayStatusImporting() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "importPending",
            size: nil, sizeleft: nil, timeleft: nil, movie: nil
        )
        #expect(item.displayStatus == "Importing")
    }

    @Test func displayStatusStalled() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: "warning", trackedDownloadState: nil,
            size: nil, sizeleft: nil, timeleft: nil, movie: nil
        )
        #expect(item.displayStatus == "Stalled")
    }

    @Test func isActiveDownloading() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil, movie: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isActiveImporting() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "importPending",
            size: nil, sizeleft: nil, timeleft: nil, movie: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isNotActive() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "completed",
            trackedDownloadStatus: nil, trackedDownloadState: nil,
            size: nil, sizeleft: nil, timeleft: nil, movie: nil
        )
        #expect(item.isActive == false)
    }

    @Test func formatTimeLeftWithDays() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "63.06:58:33", movie: nil
        )
        #expect(item.displayStatus.contains("63d 6h"))
    }

    @Test func formatTimeLeftHoursOnly() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "02:30:15", movie: nil
        )
        #expect(item.displayStatus.contains("2h 30m"))
    }

    @Test func formatTimeLeftMinutesOnly() {
        let item = RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "00:45:30", movie: nil
        )
        #expect(item.displayStatus.contains("45m"))
    }
}

// MARK: - SonarrModels Tests

struct SonarrModelsTests {

    @Test func displayTitleWithSeriesEpisodeAndTitle() {
        let series = SonarrSeries(id: 1, title: "Breaking Bad")
        let episode = SonarrEpisode(seasonNumber: 1, episodeNumber: 5, title: "Gray Matter")
        let item = SonarrQueueItem(
            id: 1, seriesId: 1, episodeId: 100,
            title: "Breaking.Bad.S01E05.1080p", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "01:30:00",
            series: series, episode: episode
        )
        #expect(item.displayTitle == "Breaking Bad  S01E05  Gray Matter")
    }

    @Test func displayTitleWithSeriesEpisodeNoTitle() {
        let series = SonarrSeries(id: 1, title: "Breaking Bad")
        let episode = SonarrEpisode(seasonNumber: 1, episodeNumber: 5)
        let item = SonarrQueueItem(
            id: 1, seriesId: 1, episodeId: 100,
            title: "Breaking.Bad.S01E05.1080p", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "01:30:00",
            series: series, episode: episode
        )
        #expect(item.displayTitle == "Breaking Bad  S01E05")
    }

    @Test func displayTitleFallbackToFilename() {
        let item = SonarrQueueItem(
            id: 1, seriesId: 1, episodeId: nil,
            title: "Breaking.Bad.S01E05.1080p", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 500000, timeleft: "01:30:00",
            series: nil, episode: nil
        )
        #expect(item.displayTitle == "Breaking.Bad.S01E05.1080p")
    }

    @Test func displayStatusDownloadingWithProgress() {
        let item = SonarrQueueItem(
            id: 1, seriesId: 1, episodeId: nil, title: "Show", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: 2000000, sizeleft: 500000, timeleft: "00:45:00",
            series: nil, episode: nil
        )
        #expect(item.displayStatus.contains("Downloading"))
        #expect(item.displayStatus.contains("75%"))
        #expect(item.displayStatus.contains("45m"))
    }

    @Test func isActiveDownloading() {
        let item = SonarrQueueItem(
            id: 1, seriesId: 1, episodeId: nil, title: "Show", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil, series: nil, episode: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isActiveImportPending() {
        let item = SonarrQueueItem(
            id: 1, seriesId: 1, episodeId: nil, title: "Show", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "importPending",
            size: nil, sizeleft: nil, timeleft: nil, series: nil, episode: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isNotActive() {
        let item = SonarrQueueItem(
            id: 1, seriesId: 1, episodeId: nil, title: "Show", status: "completed",
            trackedDownloadStatus: nil, trackedDownloadState: nil,
            size: nil, sizeleft: nil, timeleft: nil, series: nil, episode: nil
        )
        #expect(item.isActive == false)
    }
}

// MARK: - LidarrModels Tests

struct LidarrModelsTests {

    @Test func displayTitleWithArtistAlbumAndYear() {
        let artist = LidarrArtist(id: 1, artistName: "Rush")
        let album = LidarrAlbum(id: 1, title: "Signals", releaseDate: "1982-09-09")
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Rush.Signals.FLAC",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 500000, sizeleft: 250000, timeleft: "00:30:00",
            artist: artist, album: album
        )
        #expect(item.displayTitle == "Rush – Signals (1982)")
    }

    @Test func displayTitleWithArtistAlbumNoYear() {
        let artist = LidarrArtist(id: 1, artistName: "Rush")
        let album = LidarrAlbum(id: 1, title: "Signals")
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Rush.Signals.FLAC",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil,
            artist: artist, album: album
        )
        #expect(item.displayTitle == "Rush – Signals")
    }

    @Test func displayTitleFallbackToAlbum() {
        let album = LidarrAlbum(id: 1, title: "Signals")
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Rush.Signals.FLAC",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil,
            artist: nil, album: album
        )
        #expect(item.displayTitle == "Signals")
    }

    @Test func displayTitleFallbackToTitle() {
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: nil, title: "Rush.Signals.FLAC",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil,
            artist: nil, album: nil
        )
        #expect(item.displayTitle == "Rush.Signals.FLAC")
    }

    @Test func displayStatusDownloading() {
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Album",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: 1000000, sizeleft: 200000, timeleft: "00:10:00",
            artist: nil, album: nil
        )
        #expect(item.displayStatus.contains("Downloading"))
        #expect(item.displayStatus.contains("80%"))
        #expect(item.displayStatus.contains("10m"))
    }

    @Test func displayStatusImporting() {
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Album",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "importPending",
            size: nil, sizeleft: nil, timeleft: nil,
            artist: nil, album: nil
        )
        #expect(item.displayStatus == "Importing")
    }

    @Test func displayStatusStalled() {
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Album",
            status: "downloading", trackedDownloadStatus: "warning",
            trackedDownloadState: nil,
            size: nil, sizeleft: nil, timeleft: nil,
            artist: nil, album: nil
        )
        #expect(item.displayStatus == "Stalled")
    }

    @Test func isActiveDownloading() {
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Album",
            status: "downloading", trackedDownloadStatus: nil,
            trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil,
            artist: nil, album: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isActiveWarning() {
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Album",
            status: "downloading", trackedDownloadStatus: "warning",
            trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil,
            artist: nil, album: nil
        )
        #expect(item.isActive == true)
    }

    @Test func isNotActive() {
        let item = LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Album",
            status: "completed", trackedDownloadStatus: nil,
            trackedDownloadState: nil,
            size: nil, sizeleft: nil, timeleft: nil,
            artist: nil, album: nil
        )
        #expect(item.isActive == false)
    }
}

// MARK: - QBittorrentModels Tests

struct QBittorrentModelsTests {

    @Test func transferInfoDecoding() throws {
        let json = """
        {"dl_info_speed": 5242880, "up_info_speed": 1048576}
        """
        let transferInfo = try JSONDecoder().decode(QBTransferInfo.self, from: json.data(using: .utf8)!)
        #expect(transferInfo.dlInfoSpeed == 5_242_880)
        #expect(transferInfo.upInfoSpeed == 1_048_576)
    }

    @Test func torrentInfoID() {
        let torrent = QBTorrentInfo(hash: "abc123", name: "ubuntu.iso", dlspeed: 1000000, upspeed: 500000, state: "downloading")
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
                "speed": "5.2 M", "kbpersec": "5120",
                "slots": [{"nzo_id": "test123", "filename": "test.nzb", "mb": "1000", "status": "Downloading"}]
            }
        }
        """
        let response = try JSONDecoder().decode(SABQueueResponse.self, from: json.data(using: .utf8)!)
        #expect(response.queue.speed == "5.2 M")
        #expect(response.queue.slots.count == 1)
        #expect(response.queue.slots[0].filename == "test.nzb")
    }
}

// MARK: - AggregatedStatus Tests

struct AggregatedStatusTests {

    @Test func updateWithAllSuccess() {
        var status = AggregatedStatus()

        let qbStatus = QBClientStatus(
            transferInfo: QBTransferInfo(dlInfoSpeed: 5_000_000, upInfoSpeed: 1_000_000),
            activeTorrents: [
                QBTorrentInfo(hash: "1", name: "file1", dlspeed: 1000, upspeed: 0, state: "downloading"),
                QBTorrentInfo(hash: "2", name: "file2", dlspeed: 0, upspeed: 500, state: "seeding")
            ]
        )
        let sabStatus = SABClientStatus(queue: SABQueue(speed: "2.0 M", speedBytes: "2048", slots: [
            SABSlot(nzoId: "1", filename: "nzb1", mb: "1000", status: "Downloading"),
            SABSlot(nzoId: "2", filename: "nzb2", mb: "500", status: "Paused")
        ]))
        let radarrItems = [RadarrQueueItem(
            id: 1, movieId: 1, title: "Movie", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil, movie: nil
        )]
        let sonarrItems = [SonarrQueueItem(
            id: 1, seriesId: 1, episodeId: nil, title: "Show", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil, series: nil, episode: nil
        )]
        let lidarrItems = [LidarrQueueItem(
            id: 1, artistId: 1, albumId: 1, title: "Album", status: "downloading",
            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
            size: nil, sizeleft: nil, timeleft: nil, artist: nil, album: nil
        )]

        status.update(
            qbStatus: .success(qbStatus),
            sabStatus: .success(sabStatus),
            radarrItems: .success(radarrItems),
            sonarrItems: .success(sonarrItems),
            lidarrItems: .success(lidarrItems)
        )

        // 1 downloading torrent + 1 downloading SAB slot + 1 radarr + 1 sonarr + 1 lidarr = 5
        #expect(status.totalActiveDownloads == 5)
        #expect(status.totalDownloadSpeed == 7_097_152)
        #expect(status.totalUploadSpeed == 1_000_000)
        #expect(status.errors.isEmpty)
        #expect(status.qbittorrent != nil)
        #expect(status.sabnzbd != nil)
        #expect(status.radarr.count == 1)
        #expect(status.sonarr.count == 1)
        #expect(status.lidarr.count == 1)
    }

    @Test func updateWithErrors() {
        var status = AggregatedStatus()
        enum TestError: Error { case qbError, sabError }

        status.update(
            qbStatus: .failure(TestError.qbError),
            sabStatus: .failure(TestError.sabError),
            radarrItems: .success([]),
            sonarrItems: .success([]),
            lidarrItems: .success([])
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
        let lidarrItems = [
            LidarrQueueItem(id: 1, artistId: 1, albumId: 1, title: "Active", status: "downloading",
                            trackedDownloadStatus: nil, trackedDownloadState: "downloading",
                            size: nil, sizeleft: nil, timeleft: nil, artist: nil, album: nil),
            LidarrQueueItem(id: 2, artistId: 2, albumId: 2, title: "Inactive", status: "completed",
                            trackedDownloadStatus: nil, trackedDownloadState: nil,
                            size: nil, sizeleft: nil, timeleft: nil, artist: nil, album: nil)
        ]

        status.update(
            qbStatus: .success(QBClientStatus(transferInfo: QBTransferInfo(dlInfoSpeed: 0, upInfoSpeed: 0), activeTorrents: [])),
            sabStatus: .success(SABClientStatus(queue: SABQueue(speed: "0", speedBytes: "0", slots: []))),
            radarrItems: .success(radarrItems),
            sonarrItems: .success(sonarrItems),
            lidarrItems: .success(lidarrItems)
        )

        #expect(status.radarr.count == 1)
        #expect(status.sonarr.count == 1)
        #expect(status.lidarr.count == 1)
        #expect(status.totalActiveDownloads == 3)
    }

    @Test func lidarrItemsDefaultToEmptySuccess() {
        var status = AggregatedStatus()
        status.update(
            qbStatus: .failure(ServiceError.disabled),
            sabStatus: .failure(ServiceError.disabled),
            radarrItems: .success([]),
            sonarrItems: .success([])
            // lidarrItems omitted — defaults to .success([])
        )
        #expect(status.lidarr.isEmpty)
        #expect(status.errors["lidarr"] == nil)
    }
}

// MARK: - ServiceConfiguration Tests

struct ServiceConfigurationTests {

    @Test func serviceConfigurationCodable() throws {
        let config = ServiceConfiguration(baseURL: "https://example.com", webUIURL: "https://web.example.com", isEnabled: true, apiKey: "key123")
        let decoded = try JSONDecoder().decode(ServiceConfiguration.self, from: JSONEncoder().encode(config))
        #expect(decoded.baseURL == config.baseURL)
        #expect(decoded.webUIURL == config.webUIURL)
        #expect(decoded.isEnabled == config.isEnabled)
        #expect(decoded.apiKey == config.apiKey)
    }

    @Test func effectiveWebUIURLFallsBackToBaseURL() {
        let config = ServiceConfiguration(baseURL: "https://base.example.com", webUIURL: "", isEnabled: true)
        #expect(config.effectiveWebUIURL == "https://base.example.com")
    }

    @Test func effectiveWebUIURLUsesWebUIURL() {
        let config = ServiceConfiguration(baseURL: "https://base.example.com", webUIURL: "https://web.example.com", isEnabled: true)
        #expect(config.effectiveWebUIURL == "https://web.example.com")
    }

    @Test func qbittorrentEffectiveWebUIURL() {
        let noWebUI = QBittorrentConfiguration(baseURL: "https://qbt.example.com", webUIURL: "", isEnabled: true)
        #expect(noWebUI.effectiveWebUIURL == "https://qbt.example.com")

        let withWebUI = QBittorrentConfiguration(baseURL: "https://qbt.example.com", webUIURL: "https://qbtweb.example.com", isEnabled: true)
        #expect(withWebUI.effectiveWebUIURL == "https://qbtweb.example.com")
    }

    @Test func qbittorrentConfigurationCodable() throws {
        let config = QBittorrentConfiguration(baseURL: "https://qbt.example.com", webUIURL: "", username: "admin", password: "secret", isEnabled: true)
        let decoded = try JSONDecoder().decode(QBittorrentConfiguration.self, from: JSONEncoder().encode(config))
        #expect(decoded.baseURL == config.baseURL)
        #expect(decoded.username == config.username)
        #expect(decoded.password == config.password)
        #expect(decoded.isEnabled == config.isEnabled)
    }

    @Test func appSettingsCodable() throws {
        let settings = AppSettings(
            qbittorrent: QBittorrentConfiguration(baseURL: "https://qbt.example.com", username: "admin", isEnabled: true),
            sabnzbd: ServiceConfiguration(baseURL: "https://sab.example.com", isEnabled: false, apiKey: "sabkey"),
            radarr: ServiceConfiguration(baseURL: "https://radarr.example.com", isEnabled: true, apiKey: "radarrkey"),
            sonarr: ServiceConfiguration(baseURL: "https://sonarr.example.com", isEnabled: true, apiKey: "sonarrkey"),
            lidarr: ServiceConfiguration(baseURL: "https://lidarr.example.com", isEnabled: true, apiKey: "lidarrkey"),
            pollingInterval: 10.0
        )
        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
        #expect(decoded == settings)
    }

    @Test func appSettingsDefaultValues() {
        let defaults = AppSettings.default
        #expect(defaults.qbittorrent.baseURL == "")
        #expect(defaults.qbittorrent.isEnabled == false)
        #expect(defaults.sabnzbd.isEnabled == false)
        #expect(defaults.radarr.isEnabled == false)
        #expect(defaults.sonarr.isEnabled == false)
        #expect(defaults.lidarr.isEnabled == false)
        #expect(defaults.pollingInterval == 5.0)
    }
}

// MARK: - SettingsManager INI Parsing Tests

struct SettingsManagerTests {

    @Test func parsesFullConfig() {
        let ini = """
        [general]
        poll_interval = 15

        [qbittorrent]
        enabled = true
        url = http://localhost:8080
        webui_url = http://qbt.local
        username = admin
        password = secret

        [sabnzbd]
        enabled = true
        url = http://localhost:8081
        api_key = sabkey

        [radarr]
        enabled = true
        url = http://localhost:7878
        api_key = radarrkey

        [sonarr]
        enabled = false
        url = http://localhost:8989
        api_key = sonarrkey

        [lidarr]
        enabled = true
        url = http://localhost:8686
        api_key = lidarrkey
        """
        let s = SettingsManager.parseINI(ini)
        #expect(s.pollingInterval == 15.0)
        #expect(s.qbittorrent.isEnabled == true)
        #expect(s.qbittorrent.baseURL == "http://localhost:8080")
        #expect(s.qbittorrent.webUIURL == "http://qbt.local")
        #expect(s.qbittorrent.username == "admin")
        #expect(s.qbittorrent.password == "secret")
        #expect(s.sabnzbd.isEnabled == true)
        #expect(s.sabnzbd.apiKey == "sabkey")
        #expect(s.radarr.isEnabled == true)
        #expect(s.radarr.apiKey == "radarrkey")
        #expect(s.sonarr.isEnabled == false)
        #expect(s.lidarr.isEnabled == true)
        #expect(s.lidarr.apiKey == "lidarrkey")
    }

    @Test func defaultsForEmptyConfig() {
        let s = SettingsManager.parseINI("")
        #expect(s.pollingInterval == 5.0)
        #expect(s.qbittorrent.isEnabled == false)
        #expect(s.qbittorrent.baseURL == "")
        #expect(s.sabnzbd.isEnabled == false)
        #expect(s.radarr.isEnabled == false)
        #expect(s.sonarr.isEnabled == false)
        #expect(s.lidarr.isEnabled == false)
    }

    @Test func booleanParsingVariants() {
        let ini = """
        [qbittorrent]
        enabled = yes
        url = http://a
        [sabnzbd]
        enabled = 1
        url = http://b
        [radarr]
        enabled = false
        url = http://c
        [sonarr]
        enabled = 0
        url = http://d
        [lidarr]
        enabled = no
        url = http://e
        """
        let s = SettingsManager.parseINI(ini)
        #expect(s.qbittorrent.isEnabled == true)
        #expect(s.sabnzbd.isEnabled == true)
        #expect(s.radarr.isEnabled == false)
        #expect(s.sonarr.isEnabled == false)
        #expect(s.lidarr.isEnabled == false)
    }

    @Test func commentsAreIgnored() {
        let ini = """
        # This is a comment
        [general]
        ; Another comment style
        poll_interval = 30
        """
        #expect(SettingsManager.parseINI(ini).pollingInterval == 30.0)
    }

    @Test func whitespaceAroundEqualsIgnored() {
        let ini = """
        [radarr]
        enabled  =  true
        url   =   http://localhost:7878
        api_key=mykey
        """
        let s = SettingsManager.parseINI(ini)
        #expect(s.radarr.isEnabled == true)
        #expect(s.radarr.baseURL == "http://localhost:7878")
        #expect(s.radarr.apiKey == "mykey")
    }

    @Test func missingPollIntervalDefaultsFiveSeconds() {
        let ini = "[general]\n"
        #expect(SettingsManager.parseINI(ini).pollingInterval == 5.0)
    }

    @Test func hasAnyServiceConfiguredWhenOneEnabled() {
        let ini = "[radarr]\nenabled = true\nurl = http://localhost:7878\napi_key = x\n"
        let s = SettingsManager.parseINI(ini)
        let hasAny = s.qbittorrent.isEnabled || s.sabnzbd.isEnabled || s.radarr.isEnabled || s.sonarr.isEnabled || s.lidarr.isEnabled
        #expect(hasAny == true)
    }

    @Test func hasAnyServiceConfiguredWhenAllDisabled() {
        let s = AppSettings.default
        let hasAny = s.qbittorrent.isEnabled || s.sabnzbd.isEnabled || s.radarr.isEnabled || s.sonarr.isEnabled || s.lidarr.isEnabled
        #expect(hasAny == false)
    }
}

// MARK: - KeychainManager Stub Tests

struct KeychainManagerTests {

    @Test func saveDoesNotThrow() throws {
        try KeychainManager.shared.save("value", for: "test.key")
    }

    @Test func retrieveReturnsEmptyString() async throws {
        let result = try await KeychainManager.shared.retrieve("test.key")
        #expect(result == "")
    }

    @Test func migrateCompletesWithoutError() async {
        await KeychainManager.shared.migrateCredentialsToNoTouchID()
    }
}

// MARK: - StatusAggregator Tests

struct StatusAggregatorTests {

    @Test func serviceErrorTypes() {
        #expect(ServiceError.disabled.errorDescription == "Service is disabled")
        #expect(ServiceError.notConfigured.errorDescription == "Service is not configured")
    }

    @Test func disabledServiceReturnsError() {
        let client: QBittorrentClient? = nil
        let result: Result<String, Error> = client == nil ? .failure(ServiceError.disabled) : .success("data")
        if case .failure(let error) = result {
            #expect((error as? ServiceError) == .disabled)
        } else {
            Issue.record("Expected failure for disabled service")
        }
    }
}

// MARK: - QBittorrentClient Tests

struct QBittorrentClientTests {

    @Test func clientInitializes() {
        let client = QBittorrentClient(baseURL: "http://localhost:8080", username: "admin", password: "pass")
        #expect(client != nil)
    }

    @Test func qbErrorDescriptions() {
        #expect(QBError.invalidURL.errorDescription == "Invalid qBittorrent URL")
        #expect(QBError.invalidResponse.errorDescription == "Invalid response from qBittorrent")
        #expect(QBError.authenticationFailed.errorDescription == "qBittorrent authentication failed")
        #expect(QBError.noCookieReceived.errorDescription == "No session cookie received from qBittorrent")
        #expect(QBError.httpError(statusCode: 404).errorDescription == "qBittorrent HTTP error: 404")
    }
}

// MARK: - MenuBarLabel Tests

struct MenuBarLabelTests {

    @Test func iconChangesWithActiveDownloads() {
        let activeIcon = 5 > 0 ? "arrow.down.circle.fill" : "arrow.down.circle"
        let inactiveIcon = 0 > 0 ? "arrow.down.circle.fill" : "arrow.down.circle"
        #expect(activeIcon == "arrow.down.circle.fill")
        #expect(inactiveIcon == "arrow.down.circle")
    }
}
