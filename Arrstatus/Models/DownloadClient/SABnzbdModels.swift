//
//  SABnzbdModels.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

// MARK: - Queue Response
struct SABQueueResponse: Codable {
    let queue: SABQueue
}

// MARK: - Queue
struct SABQueue: Codable {
    let speed: String        // e.g., "5.2 M"
    let speedBytes: String   // e.g., "5242880"
    let slots: [SABSlot]

    enum CodingKeys: String, CodingKey {
        case speed
        case speedBytes = "kbpersec"
        case slots
    }

    var speedBytesInt: Int64 {
        // Convert kbpersec to bytes per second
        if let kbps = Double(speedBytes) {
            return Int64(kbps * 1024)
        }
        return 0
    }
}

// MARK: - Slot
struct SABSlot: Codable, Identifiable {
    let nzoId: String
    let filename: String
    let mb: String           // Size in MB
    let status: String       // Downloading, Paused, etc.

    enum CodingKeys: String, CodingKey {
        case nzoId = "nzo_id"
        case filename
        case mb
        case status
    }

    var id: String { nzoId }
}

// MARK: - Client Status
struct SABClientStatus {
    let queue: SABQueue
}
