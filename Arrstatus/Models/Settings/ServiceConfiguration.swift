//
//  ServiceConfiguration.swift
//  Arrstatus
//

import Foundation

// MARK: - Service Configuration

struct ServiceConfiguration: Codable, Equatable {
    var baseURL: String
    var webUIURL: String
    var isEnabled: Bool
    var apiKey: String

    init(baseURL: String = "", webUIURL: String = "", isEnabled: Bool = false, apiKey: String = "") {
        self.baseURL = baseURL
        self.webUIURL = webUIURL
        self.isEnabled = isEnabled
        self.apiKey = apiKey
    }

    var effectiveWebUIURL: String {
        webUIURL.isEmpty ? baseURL : webUIURL
    }
}

// MARK: - QBittorrent Configuration

struct QBittorrentConfiguration: Codable, Equatable {
    var baseURL: String
    var webUIURL: String
    var username: String
    var password: String
    var isEnabled: Bool

    init(baseURL: String = "", webUIURL: String = "", username: String = "", password: String = "", isEnabled: Bool = false) {
        self.baseURL = baseURL
        self.webUIURL = webUIURL
        self.username = username
        self.password = password
        self.isEnabled = isEnabled
    }

    var effectiveWebUIURL: String {
        webUIURL.isEmpty ? baseURL : webUIURL
    }
}

// MARK: - App Settings

struct AppSettings: Codable, Equatable {
    var qbittorrent: QBittorrentConfiguration
    var sabnzbd: ServiceConfiguration
    var radarr: ServiceConfiguration
    var sonarr: ServiceConfiguration
    var lidarr: ServiceConfiguration
    var pollingInterval: TimeInterval

    init(
        qbittorrent: QBittorrentConfiguration = QBittorrentConfiguration(),
        sabnzbd: ServiceConfiguration = ServiceConfiguration(),
        radarr: ServiceConfiguration = ServiceConfiguration(),
        sonarr: ServiceConfiguration = ServiceConfiguration(),
        lidarr: ServiceConfiguration = ServiceConfiguration(),
        pollingInterval: TimeInterval = 5.0
    ) {
        self.qbittorrent = qbittorrent
        self.sabnzbd = sabnzbd
        self.radarr = radarr
        self.sonarr = sonarr
        self.lidarr = lidarr
        self.pollingInterval = pollingInterval
    }

    static var `default`: AppSettings { AppSettings() }
}
