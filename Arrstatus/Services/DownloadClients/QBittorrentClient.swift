//
//  QBittorrentClient.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

@Observable
class QBittorrentClient {
    private let baseURL: String
    private let username: String
    private let password: String
    private var isAuthenticated = false
    private let cookieStorage: HTTPCookieStorage

    private let session: URLSession

    init(baseURL: String, username: String, password: String) {
        self.baseURL = baseURL
        self.username = username
        self.password = password

        // Use ephemeral configuration with automatic cookie handling
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true

        self.session = URLSession(configuration: config)
        self.cookieStorage = config.httpCookieStorage ?? HTTPCookieStorage.shared
    }

    // MARK: - Authentication

    func testConnection() async throws {
        // Simpler test that just validates credentials without storing cookie
        guard let url = URL(string: "\(baseURL)/api/v2/auth/login") else {
            throw QBError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "username=\(username)&password=\(password)"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw QBError.authenticationFailed
        }

        // Check response body
        if let responseString = String(data: data, encoding: .utf8),
           responseString.contains("Fails") {
            throw QBError.authenticationFailed
        }

        // Authentication succeeded - that's all we need for testing
    }

    func login() async throws {
        print("🔐 qBittorrent: Attempting authentication to \(baseURL)")

        guard let url = URL(string: "\(baseURL)/api/v2/auth/login") else {
            throw QBError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = "username=\(username)&password=\(password)"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QBError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw QBError.authenticationFailed
        }

        // Check response body
        if let responseString = String(data: data, encoding: .utf8),
           responseString.contains("Fails") {
            throw QBError.authenticationFailed
        }

        // Verify cookie was stored automatically by URLSession
        // Check all cookies in storage for the SID cookie
        if let allCookies = cookieStorage.cookies,
           allCookies.contains(where: { $0.name == "SID" }) {
            isAuthenticated = true
            print("✅ qBittorrent authenticated successfully, SID cookie received")
        } else {
            // Log available cookies for debugging
            let cookieNames = cookieStorage.cookies?.map { $0.name }.joined(separator: ", ") ?? "none"
            print("⚠️ qBittorrent: No SID cookie found. Available cookies: \(cookieNames)")
            throw QBError.noCookieReceived
        }
    }

    // MARK: - API Methods

    func getTransferInfo() async throws -> QBTransferInfo {
        let data = try await makeAuthenticatedRequest(path: "/api/v2/transfer/info")
        let decoder = JSONDecoder()
        return try decoder.decode(QBTransferInfo.self, from: data)
    }

    func getTorrents(filter: String = "all") async throws -> [QBTorrentInfo] {
        let data = try await makeAuthenticatedRequest(path: "/api/v2/torrents/info?filter=\(filter)")
        let decoder = JSONDecoder()
        return try decoder.decode([QBTorrentInfo].self, from: data)
    }

    func fetchStatus() async throws -> QBClientStatus {
        // Fetch transfer info and active torrents in parallel
        async let transferInfo = getTransferInfo()
        async let torrents = getTorrents(filter: "downloading")

        return QBClientStatus(
            transferInfo: try await transferInfo,
            activeTorrents: try await torrents
        )
    }

    // MARK: - Private Methods

    private func makeAuthenticatedRequest(path: String, retryCount: Int = 0) async throws -> Data {
        // Ensure we're logged in
        if !isAuthenticated {
            try await login()
        }

        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw QBError.invalidURL
        }

        let request = URLRequest(url: url)
        // Cookies are now automatically handled by URLSession

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QBError.invalidResponse
        }

        // Handle authentication failure - retry with exponential backoff
        if httpResponse.statusCode == 403 && retryCount < 3 {
            print("⚠️ qBittorrent: Authentication expired, retrying... (attempt \(retryCount + 1))")
            isAuthenticated = false

            // Exponential backoff: 1s, 2s, 4s
            let delay = TimeInterval(1 << retryCount)
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            try await login()
            return try await makeAuthenticatedRequest(path: path, retryCount: retryCount + 1)
        }

        guard httpResponse.statusCode == 200 else {
            throw QBError.httpError(statusCode: httpResponse.statusCode)
        }

        return data
    }
}

// MARK: - Errors

enum QBError: LocalizedError {
    case invalidURL
    case invalidResponse
    case authenticationFailed
    case noCookieReceived
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid qBittorrent URL"
        case .invalidResponse:
            return "Invalid response from qBittorrent"
        case .authenticationFailed:
            return "qBittorrent authentication failed"
        case .noCookieReceived:
            return "No session cookie received from qBittorrent"
        case .httpError(let code):
            return "qBittorrent HTTP error: \(code)"
        }
    }
}
