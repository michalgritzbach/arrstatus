//
//  QBittorrentModels.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

// MARK: - Transfer Info
struct QBTransferInfo: Codable {
    let dlInfoSpeed: Int64   // Global download speed in bytes/s
    let upInfoSpeed: Int64   // Global upload speed in bytes/s

    enum CodingKeys: String, CodingKey {
        case dlInfoSpeed = "dl_info_speed"
        case upInfoSpeed = "up_info_speed"
    }
}

// MARK: - Torrent Info
struct QBTorrentInfo: Codable, Identifiable {
    let hash: String
    let name: String
    let dlspeed: Int64      // Download speed in bytes/s
    let upspeed: Int64      // Upload speed in bytes/s
    let state: String       // downloading, uploading, stalledDL, etc.

    var id: String { hash }
}

// MARK: - Client Status
struct QBClientStatus {
    let transferInfo: QBTransferInfo
    let activeTorrents: [QBTorrentInfo]
}
