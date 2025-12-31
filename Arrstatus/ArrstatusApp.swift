//
//  ArrstatusApp.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

@main
struct ArrstatusApp: App {
    @State private var statusAggregator: StatusAggregator
    @State private var settingsManager = SettingsManager.shared
    @State private var showOnboarding: Bool = false

    init() {
        // Initialize aggregator with settings manager
        _statusAggregator = State(initialValue: StatusAggregator(settingsManager: .shared))

        // Check if onboarding should be shown
        _showOnboarding = State(initialValue: SettingsManager.shared.isFirstLaunch ||
                                             !SettingsManager.shared.hasAnyServiceConfigured)
    }

    var body: some Scene {
        // Main menu bar
        MenuBarExtra {
            MenuBarContentView()
                .environment(statusAggregator)
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                }
                .task {
                    // Migrate credentials to remove Touch ID requirement (one-time)
                    await KeychainManager.shared.migrateCredentialsToNoTouchID()
                }
        } label: {
            MenuBarLabel(
                totalDownloads: statusAggregator.totalActiveDownloads,
                aggregatedSpeed: statusAggregator.totalDownloadSpeed,
                hasServicesEnabled: settingsManager.hasAnyServiceConfigured
            )
        }

        // Settings window (macOS 15+)
        Settings {
            SettingsView()
        }
    }
}
