//
//  RadarrClient.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

@Observable
class RadarrClient {
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

    func getQueue() async throws -> [RadarrQueueItem] {
        guard let url = URL(string: "\(baseURL)/api/v3/queue?includeMovie=true") else {
            throw RadarrError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RadarrError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw RadarrError.authenticationFailed
            }
            throw RadarrError.httpError(statusCode: httpResponse.statusCode)
        }

        // Debug: Print raw JSON response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 Radarr Queue Response (first 500 chars):")
            print(String(jsonString.prefix(500)))
        }

        // Parse response - Radarr returns { "records": [...] }
        let decoder = JSONDecoder()
        if let queueResponse = try? decoder.decode(RadarrQueueResponse.self, from: data) {
            // Debug: Print first item details
            if let firstItem = queueResponse.records.first {
                print("🔍 First Radarr item: id=\(firstItem.id), movieId=\(firstItem.movieId), movie.id=\(firstItem.movie?.id ?? -1), movie.tmdbId=\(firstItem.movie?.tmdbId ?? -1)")
            }
            return queueResponse.records
        }

        // Fallback: try parsing as array directly
        return try decoder.decode([RadarrQueueItem].self, from: data)
    }

    func getActiveItems() async throws -> [RadarrQueueItem] {
        let allItems = try await getQueue()
        return allItems.filter { $0.isActive }
    }
}

// MARK: - Queue Response Wrapper

private struct RadarrQueueResponse: Codable {
    let records: [RadarrQueueItem]
}

// MARK: - Errors

enum RadarrError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Radarr URL"
        case .invalidResponse:
            return "Invalid response from Radarr"
        case .httpError(let code):
            return "Radarr HTTP error: \(code)"
        case .authenticationFailed:
            return "Radarr authentication failed - check API key"
        }
    }
}
