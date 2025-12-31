//
//  ServiceConfiguration.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

// MARK: - Service Configuration

struct ServiceConfiguration: Codable, Equatable {
    var baseURL: String
    var webUIURL: String
    var isEnabled: Bool

    init(baseURL: String = "", webUIURL: String = "", isEnabled: Bool = false) {
        self.baseURL = baseURL
        self.webUIURL = webUIURL
        self.isEnabled = isEnabled
    }
}

// MARK: - QBittorrent Configuration

struct QBittorrentConfiguration: Codable, Equatable {
    var baseURL: String
    var webUIURL: String
    var username: String
    var isEnabled: Bool

    init(baseURL: String = "", webUIURL: String = "", username: String = "", isEnabled: Bool = false) {
        self.baseURL = baseURL
        self.webUIURL = webUIURL
        self.username = username
        self.isEnabled = isEnabled
    }
}

// MARK: - App Settings

struct AppSettings: Codable, Equatable {
    var qbittorrent: QBittorrentConfiguration
    var sabnzbd: ServiceConfiguration
    var radarr: ServiceConfiguration
    var sonarr: ServiceConfiguration
    var pollingInterval: TimeInterval

    static var `default`: AppSettings {
        AppSettings(
            qbittorrent: QBittorrentConfiguration(),
            sabnzbd: ServiceConfiguration(),
            radarr: ServiceConfiguration(),
            sonarr: ServiceConfiguration(),
            pollingInterval: 5.0
        )
    }
}
