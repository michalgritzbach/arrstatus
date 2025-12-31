//
//  ArrstatusApp.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

@main
struct ArrstatusApp: App {
    @State private var statusAggregator = StatusAggregator()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environment(statusAggregator)
        } label: {
            MenuBarLabel(
                totalDownloads: statusAggregator.totalActiveDownloads,
                aggregatedSpeed: statusAggregator.totalDownloadSpeed
            )
        }
    }
}
