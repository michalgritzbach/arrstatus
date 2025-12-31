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

    var body: some View {
        HStack {
            Image(systemName: totalDownloads > 0 ? "arrow.down.circle.fill" : "arrow.down.circle")
            Text("\(totalDownloads) @ \(formatSpeed(aggregatedSpeed))")
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

#Preview {
    MenuBarLabel(totalDownloads: 3, aggregatedSpeed: 5_242_880)
}
