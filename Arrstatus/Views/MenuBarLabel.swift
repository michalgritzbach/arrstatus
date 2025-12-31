//
//  MenuBarLabel.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

struct MenuBarLabel: View {
    let totalDownloads: Int
    let aggregatedSpeed: Int64
    let hasServicesEnabled: Bool

    var body: some View {
        HStack {
            if hasServicesEnabled {
                // Show download stats when services are enabled
                Image(systemName: totalDownloads > 0 ? "arrow.down.circle.fill" : "arrow.down.circle")
                Text("\(totalDownloads) @ \(formatSpeed(aggregatedSpeed))")
            } else {
                // Show app name when no services are enabled
                Image(systemName: "arrow.down.circle")
                Text("Arrstatus")
            }
        }
    }

    private func formatSpeed(_ bytesPerSecond: Int64) -> String {
        let kb = Double(bytesPerSecond) / 1024
        let mb = kb / 1024

        if mb >= 1 {
            return String(format: "%.1f MB/s", mb)
        } else if kb >= 1 {
            return String(format: "%.0f KB/s", kb)
        } else {
            return "\(bytesPerSecond) B/s"
        }
    }
}

#Preview("With Services") {
    MenuBarLabel(totalDownloads: 3, aggregatedSpeed: 5_242_880, hasServicesEnabled: true)
}

#Preview("No Services") {
    MenuBarLabel(totalDownloads: 0, aggregatedSpeed: 0, hasServicesEnabled: false)
}
