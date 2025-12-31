//
//  FormatHelpers.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

enum FormatHelpers {
    static func formatSpeed(_ bytesPerSecond: Int64) -> String {
        let kb = Double(bytesPerSecond) / 1024
        let mb = kb / 1024
        let gb = mb / 1024

        if gb >= 1 {
            return String(format: "%.2f GB/s", gb)
        } else if mb >= 1 {
            return String(format: "%.2f MB/s", mb)
        } else if kb >= 1 {
            return String(format: "%.1f KB/s", kb)
        } else {
            return "\(bytesPerSecond) B/s"
        }
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        let tb = gb / 1024

        if tb >= 1 {
            return String(format: "%.2f TB", tb)
        } else if gb >= 1 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1 {
            return String(format: "%.1f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }
}
