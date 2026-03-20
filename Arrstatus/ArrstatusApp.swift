//
//  ArrstatusApp.swift
//  Arrstatus
//

import SwiftUI

@main
struct ArrstatusApp: App {
    @State private var statusAggregator = StatusAggregator()
    @State private var settingsManager = SettingsManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environment(statusAggregator)
        } label: {
            MenuBarLabel(
                totalDownloads: statusAggregator.totalActiveDownloads,
                aggregatedSpeed: statusAggregator.totalDownloadSpeed,
                hasServicesEnabled: settingsManager.hasAnyServiceConfigured
            )
        }
    }
}
