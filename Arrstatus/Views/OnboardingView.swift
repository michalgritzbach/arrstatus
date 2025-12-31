//
//  OnboardingView.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Welcome to Arrstatus")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Monitor your download clients and media management services from your menu bar.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 400)

            VStack(spacing: 12) {
                Button(action: {
                    isPresented = false
                    openSettings()
                }) {
                    Label("Configure Services", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip for Now") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: 300)
        }
        .padding(40)
        .frame(width: 500, height: 400)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
