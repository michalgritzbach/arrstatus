//
//  StatusAggregator.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

@Observable
class StatusAggregator {
    // Client instances
    private let qbClient: QBittorrentClient
    private let sabClient: SABnzbdClient
    private let radarrClient: RadarrClient
    private let sonarrClient: SonarrClient

    // Current aggregated state
    private(set) var status = AggregatedStatus()

    // Polling control
    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval

    // Computed properties for menubar
    var totalActiveDownloads: Int {
        status.totalActiveDownloads
    }

    var totalDownloadSpeed: Int64 {
        status.totalDownloadSpeed
    }

    init() {
        // Initialize all clients with configuration
        self.qbClient = QBittorrentClient(
            baseURL: AppConfiguration.QBittorrent.baseURL,
            username: AppConfiguration.QBittorrent.username,
            password: AppConfiguration.QBittorrent.password
        )

        self.sabClient = SABnzbdClient(
            baseURL: AppConfiguration.SABnzbd.baseURL,
            apiKey: AppConfiguration.SABnzbd.apiKey
        )

        self.radarrClient = RadarrClient(
            baseURL: AppConfiguration.Radarr.baseURL,
            apiKey: AppConfiguration.Radarr.apiKey
        )

        self.sonarrClient = SonarrClient(
            baseURL: AppConfiguration.Sonarr.baseURL,
            apiKey: AppConfiguration.Sonarr.apiKey
        )

        self.pollingInterval = AppConfiguration.PollingInterval.seconds

        // Start polling
        startPolling()
    }

    deinit {
        stopPolling()
    }

    // MARK: - Polling Control

    func startPolling() {
        // Create timer on main thread
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: pollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAllData()
            }
        }

        // Trigger immediate refresh
        Task { @MainActor in
            await refreshAllData()
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Data Fetching

    @MainActor
    private func refreshAllData() async {
        // Fetch from all clients in parallel
        async let qbStatus = fetchQBittorrentStatus()
        async let sabStatus = fetchSABnzbdStatus()
        async let radarrItems = fetchRadarrQueue()
        async let sonarrItems = fetchSonarrQueue()

        // Await all results
        let results = await (qbStatus, sabStatus, radarrItems, sonarrItems)

        // Update aggregated status
        status.update(
            qbStatus: results.0,
            sabStatus: results.1,
            radarrItems: results.2,
            sonarrItems: results.3
        )

        // Log summary
        print("📊 Status updated: \(status.totalActiveDownloads) downloads, \(FormatHelpers.formatSpeed(status.totalDownloadSpeed))")
    }

    private func fetchQBittorrentStatus() async -> Result<QBClientStatus, Error> {
        do {
            let status = try await qbClient.fetchStatus()
            print("✅ qBittorrent: DL \(FormatHelpers.formatSpeed(status.transferInfo.dlInfoSpeed)), \(status.activeTorrents.count) active")
            return .success(status)
        } catch {
            print("❌ qBittorrent fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchSABnzbdStatus() async -> Result<SABClientStatus, Error> {
        do {
            let status = try await sabClient.fetchStatus()
            print("✅ SABnzbd: DL \(FormatHelpers.formatSpeed(status.queue.speedBytesInt)), \(status.queue.slots.count) items")
            return .success(status)
        } catch {
            print("❌ SABnzbd fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchRadarrQueue() async -> Result<[RadarrQueueItem], Error> {
        do {
            let items = try await radarrClient.getActiveItems()
            print("✅ Radarr: \(items.count) active items")
            return .success(items)
        } catch {
            print("❌ Radarr fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchSonarrQueue() async -> Result<[SonarrQueueItem], Error> {
        do {
            let items = try await sonarrClient.getActiveItems()
            print("✅ Sonarr: \(items.count) active items")
            return .success(items)
        } catch {
            print("❌ Sonarr fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
