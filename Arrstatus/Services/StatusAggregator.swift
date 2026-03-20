//
//  StatusAggregator.swift
//  Arrstatus
//

import Foundation
import Combine

@Observable
class StatusAggregator {
    private var qbClient: QBittorrentClient?
    private var sabClient: SABnzbdClient?
    private var radarrClient: RadarrClient?
    private var sonarrClient: SonarrClient?
    private var lidarrClient: LidarrClient?

    private let settingsManager: SettingsManager
    private(set) var status = AggregatedStatus()

    private var pollingTimer: Timer?
    private var pollingInterval: TimeInterval
    private var cancellables = Set<AnyCancellable>()

    var totalActiveDownloads: Int { status.totalActiveDownloads }
    var totalDownloadSpeed: Int64 { status.totalDownloadSpeed }

    init(settingsManager: SettingsManager = .shared) {
        self.settingsManager = settingsManager
        self.pollingInterval = settingsManager.settings.pollingInterval

        settingsManager.configurationDidChange
            .sink { [weak self] in
                Task { @MainActor in
                    await self?.reconfigure()
                }
            }
            .store(in: &cancellables)

        Task { @MainActor in
            await reconfigure()
        }
    }

    deinit { stopPolling() }

    // MARK: - Configuration

    @MainActor
    private func reconfigure() async {
        stopPolling()
        let settings = settingsManager.settings

        // QBittorrent
        if settings.qbittorrent.isEnabled,
           !settings.qbittorrent.baseURL.isEmpty,
           !settings.qbittorrent.password.isEmpty {
            qbClient = QBittorrentClient(
                baseURL: settings.qbittorrent.baseURL,
                username: settings.qbittorrent.username,
                password: settings.qbittorrent.password
            )
            print("✅ QBittorrent client configured")
        } else {
            qbClient = nil
            print("⚠️ QBittorrent client disabled or not configured")
        }

        // SABnzbd
        if settings.sabnzbd.isEnabled,
           !settings.sabnzbd.baseURL.isEmpty,
           !settings.sabnzbd.apiKey.isEmpty {
            sabClient = SABnzbdClient(baseURL: settings.sabnzbd.baseURL, apiKey: settings.sabnzbd.apiKey)
            print("✅ SABnzbd client configured")
        } else {
            sabClient = nil
            print("⚠️ SABnzbd client disabled or not configured")
        }

        // Radarr
        if settings.radarr.isEnabled,
           !settings.radarr.baseURL.isEmpty,
           !settings.radarr.apiKey.isEmpty {
            radarrClient = RadarrClient(baseURL: settings.radarr.baseURL, apiKey: settings.radarr.apiKey)
            print("✅ Radarr client configured")
        } else {
            radarrClient = nil
            print("⚠️ Radarr client disabled or not configured")
        }

        // Sonarr
        if settings.sonarr.isEnabled,
           !settings.sonarr.baseURL.isEmpty,
           !settings.sonarr.apiKey.isEmpty {
            sonarrClient = SonarrClient(baseURL: settings.sonarr.baseURL, apiKey: settings.sonarr.apiKey)
            print("✅ Sonarr client configured")
        } else {
            sonarrClient = nil
            print("⚠️ Sonarr client disabled or not configured")
        }

        // Lidarr
        if settings.lidarr.isEnabled,
           !settings.lidarr.baseURL.isEmpty,
           !settings.lidarr.apiKey.isEmpty {
            lidarrClient = LidarrClient(baseURL: settings.lidarr.baseURL, apiKey: settings.lidarr.apiKey)
            print("✅ Lidarr client configured")
        } else {
            lidarrClient = nil
            print("⚠️ Lidarr client disabled or not configured")
        }

        pollingInterval = settings.pollingInterval

        if hasAnyEnabledService {
            startPolling()
        } else {
            print("⚠️ No services enabled - polling not started")
        }
    }

    private var hasAnyEnabledService: Bool {
        qbClient != nil || sabClient != nil || radarrClient != nil || sonarrClient != nil || lidarrClient != nil
    }

    // MARK: - Polling Control

    func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAllData()
            }
        }
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
        async let qbStatus = fetchQBittorrentStatus()
        async let sabStatus = fetchSABnzbdStatus()
        async let radarrItems = fetchRadarrQueue()
        async let sonarrItems = fetchSonarrQueue()
        async let lidarrItems = fetchLidarrQueue()

        let results = await (qbStatus, sabStatus, radarrItems, sonarrItems, lidarrItems)

        status.update(
            qbStatus: results.0,
            sabStatus: results.1,
            radarrItems: results.2,
            sonarrItems: results.3,
            lidarrItems: results.4
        )

        print("📊 Status updated: \(status.totalActiveDownloads) downloads, \(FormatHelpers.formatSpeed(status.totalDownloadSpeed))")
    }

    private func fetchQBittorrentStatus() async -> Result<QBClientStatus, Error> {
        guard let client = qbClient else { return .failure(ServiceError.disabled) }
        do {
            let s = try await client.fetchStatus()
            print("✅ qBittorrent: DL \(FormatHelpers.formatSpeed(s.transferInfo.dlInfoSpeed)), \(s.activeTorrents.count) active")
            return .success(s)
        } catch {
            print("❌ qBittorrent fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchSABnzbdStatus() async -> Result<SABClientStatus, Error> {
        guard let client = sabClient else { return .failure(ServiceError.disabled) }
        do {
            let s = try await client.fetchStatus()
            print("✅ SABnzbd: DL \(FormatHelpers.formatSpeed(s.queue.speedBytesInt)), \(s.queue.slots.count) items")
            return .success(s)
        } catch {
            print("❌ SABnzbd fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchRadarrQueue() async -> Result<[RadarrQueueItem], Error> {
        guard let client = radarrClient else { return .failure(ServiceError.disabled) }
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
        guard let client = sonarrClient else { return .failure(ServiceError.disabled) }
        do {
            let items = try await client.getActiveItems()
            print("✅ Sonarr: \(items.count) active items")
            return .success(items)
        } catch {
            print("❌ Sonarr fetch error: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func fetchLidarrQueue() async -> Result<[LidarrQueueItem], Error> {
        guard let client = lidarrClient else { return .failure(ServiceError.disabled) }
        do {
            let items = try await client.getActiveItems()
            print("✅ Lidarr: \(items.count) active items")
            return .success(items)
        } catch {
            print("❌ Lidarr fetch error: \(error.localizedDescription)")
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
        case .disabled: return "Service is disabled"
        case .notConfigured: return "Service is not configured"
        }
    }
}
