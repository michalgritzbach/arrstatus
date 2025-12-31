//
//  KeychainManager.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation
import Security
import LocalAuthentication

// MARK: - Keychain Error

enum KeychainError: LocalizedError, Equatable {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unhandledError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in keychain"
        case .duplicateItem:
            return "Item already exists in keychain"
        case .invalidData:
            return "Invalid data format"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.arrstatus"

    // Shared authentication context to avoid multiple Touch ID prompts
    private var authenticationContext: LAContext?
    private var contextCreationTime: Date?
    private let contextValidityDuration: TimeInterval = 60 // 60 seconds

    // Setting to control Touch ID requirement
    var requireTouchID: Bool {
        get { UserDefaults.standard.bool(forKey: "arrstatus.security.requireTouchID") }
        set { UserDefaults.standard.set(newValue, forKey: "arrstatus.security.requireTouchID") }
    }

    private init() {
        // Default to Touch ID disabled for better UX (can be enabled in settings)
        if UserDefaults.standard.object(forKey: "arrstatus.security.requireTouchID") == nil {
            requireTouchID = false
        }
    }

    // MARK: - Migration

    func migrateCredentialsToNoTouchID() async {
        // Only run migration once
        guard !UserDefaults.standard.bool(forKey: "arrstatus.security.migrated") else {
            return
        }

        print("🔄 Migrating credentials to remove Touch ID requirement...")

        let credentialKeys = [
            "qbittorrent.password",
            "sabnzbd.apikey",
            "radarr.apikey",
            "sonarr.apikey"
        ]

        for key in credentialKeys {
            do {
                // Try to retrieve the credential (may prompt for Touch ID if stored with .userPresence)
                if let value = try? await retrieve(key) {
                    // Delete the old credential
                    try? delete(key)
                    // Re-save without Touch ID requirement
                    try save(value, for: key)
                    print("✅ Migrated credential: \(key)")
                }
            } catch {
                print("⚠️ Could not migrate credential \(key): \(error.localizedDescription)")
            }
        }

        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: "arrstatus.security.migrated")
        print("✅ Credential migration complete")
    }

    // MARK: - Authentication Context

    private func getAuthenticationContext() async -> LAContext {
        // Create new context if none exists or if it's expired
        if let context = authenticationContext,
           let creationTime = contextCreationTime,
           Date().timeIntervalSince(creationTime) < contextValidityDuration {
            return context
        }

        // Create new context
        let context = LAContext()
        context.localizedReason = "Authenticate to access Arrstatus credentials"
        context.touchIDAuthenticationAllowableReuseDuration = 60 // Allow reuse for 60 seconds

        // Pre-authenticate the context to enable reuse
        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate to access Arrstatus credentials")
            authenticationContext = context
            contextCreationTime = Date()
        } catch {
            // If authentication fails, still return the context
            // The Keychain operation will handle the error
            print("Pre-authentication failed: \(error.localizedDescription)")
        }

        return context
    }

    // Invalidate the context (e.g., after credential operations are done)
    func invalidateAuthenticationContext() {
        authenticationContext?.invalidate()
        authenticationContext = nil
        contextCreationTime = nil
    }

    // MARK: - Save

    func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        // Delete existing item if present
        try? delete(key)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Only use Touch ID if explicitly enabled
        if requireTouchID, #available(macOS 10.15, *) {
            // Create access control with biometry support
            if let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .userPresence, // Requires Touch ID or password on every access
                nil
            ) {
                query[kSecAttrAccessControl as String] = access
            } else {
                query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        } else {
            // No Touch ID - accessible when unlocked (more convenient)
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Retrieve

    func retrieve(_ key: String) async throws -> String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Use shared authentication context only if Touch ID is required
        if requireTouchID, #available(macOS 10.15, *) {
            let context = await getAuthenticationContext()
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return string
    }

    // Synchronous retrieve for backwards compatibility (uses blocking call)
    func retrieve(_ key: String) throws -> String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Use shared context if available and Touch ID is required
        if requireTouchID,
           #available(macOS 10.15, *),
           let context = authenticationContext,
           let creationTime = contextCreationTime,
           Date().timeIntervalSince(creationTime) < contextValidityDuration {
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return string
    }

    // MARK: - Delete

    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
