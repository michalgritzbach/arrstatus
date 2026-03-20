//
//  KeychainManager.swift
//  Arrstatus
//
//  Stub — credentials are now stored in ~/.config/arrstatus/arrstatus.conf
//

import Foundation

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    func save(_ value: String, for key: String) throws {}
    func retrieve(_ key: String) async throws -> String { "" }
    func migrateCredentialsToNoTouchID() async {}
}
