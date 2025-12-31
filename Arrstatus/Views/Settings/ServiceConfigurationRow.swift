//
//  ServiceConfigurationRow.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import SwiftUI

struct ServiceConfigurationRow: View {
    let serviceName: String
    let iconName: String
    @Binding var isEnabled: Bool
    @Binding var baseURL: String
    @Binding var webUIURL: String
    @Binding var credential: String
    let credentialLabel: String
    let onTestConnection: () async -> Result<Void, Error>

    @State private var isExpanded: Bool = false
    @State private var testResult: Result<Void, Error>?
    @State private var isTesting: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with toggle
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                Toggle(serviceName, isOn: $isEnabled)
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

                    // Credential (secure field)
                    LabeledContent("\(credentialLabel):") {
                        SecureField("Enter \(credentialLabel.lowercased())", text: $credential)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 300)
                    }

                    // Test connection button
                    HStack {
                        Button(action: testConnection) {
                            Label(isTesting ? "Testing..." : "Test Connection",
                                  systemImage: isTesting ? "circle.dotted" : "network")
                        }
                        .disabled(isTesting || baseURL.isEmpty || credential.isEmpty)

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
