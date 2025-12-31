//
//  QBittorrentConfigurationRow.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

struct QBittorrentConfigurationRow: View {
    @Binding var isEnabled: Bool
    @Binding var baseURL: String
    @Binding var webUIURL: String
    @Binding var username: String
    @Binding var password: String
    let onTestConnection: () async -> Result<Void, Error>

    @State private var isExpanded: Bool = false
    @State private var testResult: Result<Void, Error>?
    @State private var isTesting: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with toggle
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                Toggle("qBittorrent", isOn: $isEnabled)
                    .toggleStyle(.switch)
                Spacer()
                Button(isExpanded ? "Hide" : "Configure") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .disabled(!isEnabled)
            }

            if isExpanded && isEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    // Base URL
                    LabeledContent("Base URL:") {
                        TextField("https://example.com", text: $baseURL)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 300)
                    }

                    // Web UI URL (optional)
                    LabeledContent("Web UI URL:") {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Optional - defaults to Base URL", text: $webUIURL)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 300)
                            Text("Leave empty to use Base URL")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Username
                    LabeledContent("Username:") {
                        TextField("Enter username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 300)
                    }

                    // Password (secure field)
                    LabeledContent("Password:") {
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 300)
                    }

                    // Test connection button
                    HStack {
                        Button(action: testConnection) {
                            Label(isTesting ? "Testing..." : "Test Connection",
                                  systemImage: isTesting ? "circle.dotted" : "network")
                        }
                        .disabled(isTesting || baseURL.isEmpty || username.isEmpty || password.isEmpty)

                        if let result = testResult {
                            switch result {
                            case .success:
                                Label("Connected", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            case .failure(let error):
                                Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .help(error.localizedDescription)
                            }
                        }
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding(.vertical, 4)
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        Task {
            let result = await onTestConnection()
            await MainActor.run {
                testResult = result
                isTesting = false
            }
        }
    }
}
