//
//  SABnzbdClient.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

@Observable
class SABnzbdClient {
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession

    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    // MARK: - API Methods

    func getQueue() async throws -> SABQueue {
        guard let url = URL(string: "\(baseURL)/api?mode=queue&apikey=\(apiKey)&output=json") else {
            throw SABError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SABError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw SABError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let queueResponse = try decoder.decode(SABQueueResponse.self, from: data)
        return queueResponse.queue
    }

    func fetchStatus() async throws -> SABClientStatus {
        let queue = try await getQueue()
        return SABClientStatus(queue: queue)
    }
}

// MARK: - Errors

enum SABError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid SABnzbd URL"
        case .invalidResponse:
            return "Invalid response from SABnzbd"
        case .httpError(let code):
            return "SABnzbd HTTP error: \(code)"
        case .authenticationFailed:
            return "SABnzbd authentication failed - check API key"
        }
    }
}
