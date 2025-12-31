//
//  AppConfiguration.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

enum AppConfiguration {
    enum PollingInterval {
        static let seconds: TimeInterval = 5.0
    }

    enum QBittorrent {
        static let baseURL = "http://localhost:8080"
        static let username = "admin"
        static let password = "your-password-here"
        static let webUIURL = "http://localhost:8080"
    }

    enum SABnzbd {
        static let baseURL = "http://localhost:8081"
        static let apiKey = "your-api-key-here"
        static let webUIURL = "http://localhost:8081"
    }

    enum Radarr {
        static let baseURL = "http://localhost:7878"
        static let apiKey = "your-radarr-api-key"
        static let webUIURL = "http://localhost:7878"
    }

    enum Sonarr {
        static let baseURL = "http://localhost:8989"
        static let apiKey = "your-sonarr-api-key"
        static let webUIURL = "http://localhost:8989"
    }
}
