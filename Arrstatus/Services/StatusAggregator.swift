//
//  StatusAggregator.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation
import Combine

@Observable
class StatusAggregator {
    // Optional client instances (dynamically created)
    private var qbClient: QBittorrentClient?
    private var sabClient: SABnzbdClient?
    private var radarrClient: RadarrClient?
    private var sonarrClient: SonarrClient?

    // Settings manager
    private let settingsManager: SettingsManager

    // Current aggregated state
    private(set) var status = AggregatedStatus()

    // Polling control
    private var pollingTimer: Timer?
    private var pollingInterval: TimeInterval

    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // Computed properties for menubar
    var totalActiveDownloads: Int {
        status.totalActiveDownloads
    }

    var totalDownloadSpeed: Int64 {
        status.totalDownloadSpeed
    }

    init(settingsManager: SettingsManager = .shared) {
        self.settingsManager = settingsManager
        self.pollingInterval = settingsManager.settings.pollingInterval

        // Subscribe to configuration changes
        settingsManager.configurationDidChange
            .sink { [weak self] in
                Task { @MainActor in
                    await self?.reconfigure()
                }
            }
            .store(in: &cancellables)

        // Initial configuration
        Task { @MainActor in
            await reconfigure()
        }
    }

    deinit {
        stopPolling()
    }

    // MARK: - Configuration

    @MainActor
    private func reconfigure() async {
        stopPolling()

        // Recreate clients based on current settings
        let settings = settingsManager.settings

        // QBittorrent
        if settings.qbittorrent.isEnabled,
           !settings.qbittorrent.baseURL.isEmpty,
           let password = settingsManager.getQBittorrentPassword(),
           !password.isEmpty {
            qbClient = QBittorrentClient(
                baseURL: settings.qbittorrent.baseURL,
                username: settings.qbittorrent.username,
                password: password
            )
            print("✅ QBittorrent client configured")
        } else {
            qbClient = nil
            print("⚠️ QBittorrent client disabled")
        }

        // SABnzbd
        if settings.sabnzbd.isEnabled,
           !settings.sabnzbd.baseURL.isEmpty,
           let apiKey = settingsManager.getSABnzbdAPIKey(),
           !apiKey.isEmpty {
            sabClient = SABnzbdClient(
                baseURL: settings.sabnzbd.baseURL,
                apiKey: apiKey
            )
            print("✅ SABnzbd client configured")
        } else {
            sabClient = nil
            print("⚠️ SABnzbd client disabled")
        }

        // Radarr
        if settings.radarr.isEnabled,
           !settings.radarr.baseURL.isEmpty,
           let apiKey = settingsManager.getRadarrAPIKey(),
           !apiKey.isEmpty {
            radarrClient = RadarrClient(
                baseURL: settings.radarr.baseURL,
                apiKey: apiKey
            )
            print("✅ Radarr client configured")
        } else {
            radarrClient = nil
            print("⚠️ Radarr client disabled")
        }

        // Sonarr
        if settings.sonarr.isEnabled,
           !settings.sonarr.baseURL.isEmpty,
           let apiKey = settingsManager.getSonarrAPIKey(),
           !apiKey.isEmpty {
            sonarrClient = SonarrClient(
                baseURL: settings.sonarr.baseURL,
                apiKey: apiKey
            )
            print("✅ Sonarr client configured")
        } else {
            sonarrClient = nil
            print("⚠️ Sonarr client disabled")
        }

        // Update polling interval
        pollingInterval = settings.pollingInterval

        // Start polling if any service is enabled
        if hasAnyEnabledService {
            startPolling()
        } else {
            print("⚠️ No services enabled - polling not started")
        }
    }

    private var hasAnyEnabledService: Bool {
        qbClient != nil || sabClient != nil || radarrClient != nil || sonarrClient != nil
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
        // Fetch from all enabled clients in parallel
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
        guard let client = qbClient else {
            return .failure(ServiceError.disabled)
        }

        do {
            let status = try await client.fetchStatus()
            print("✅ qBittorrent: DL \(FormatHelpers.formatSpeed(status.transferInfo.dlInfoSpeed)), \(status.activeTorrents.count) active")
            return .success(status)
        } catch {
            print("❌ qBittorrent fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchSABnzbdStatus() async -> Result<SABClientStatus, Error> {
        guard let client = sabClient else {
            return .failure(ServiceError.disabled)
        }

        do {
            let status = try await client.fetchStatus()
            print("✅ SABnzbd: DL \(FormatHelpers.formatSpeed(status.queue.speedBytesInt)), \(status.queue.slots.count) items")
            return .success(status)
        } catch {
            print("❌ SABnzbd fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchRadarrQueue() async -> Result<[RadarrQueueItem], Error> {
        guard let client = radarrClient else {
            return .failure(ServiceError.disabled)
        }

        do {
            let items = try await client.getActiveItems()
            print("✅ Radarr: \(items.count) active items")
            return .success(items)
        } catch {
            print("❌ Radarr fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchSonarrQueue() async -> Result<[SonarrQueueItem], Error> {
        guard let client = sonarrClient else {
            return .failure(ServiceError.disabled)
        }

        do {
            let items = try await client.getActiveItems()
            print("✅ Sonarr: \(items.count) active items")
            return .success(items)
        } catch {
            print("❌ Sonarr fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}

// MARK: - Service Error

enum ServiceError: LocalizedError {
    case disabled
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .disabled:
            return "Service is disabled"
        case .notConfigured:
            return "Service is not configured"
        }
    }
}
