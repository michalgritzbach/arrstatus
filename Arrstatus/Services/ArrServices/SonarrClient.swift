//
//  SonarrClient.swift
//  Arrstatus
//
//  Created by Michal Gritzbach on 31.12.2025.
//

import Foundation

@Observable
class SonarrClient {
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

    func getQueue() async throws -> [SonarrQueueItem] {
        guard let url = URL(string: "\(baseURL)/api/v3/queue?includeSeries=true&includeEpisode=true") else {
            throw SonarrError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SonarrError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw SonarrError.authenticationFailed
            }
            throw SonarrError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response - Sonarr returns { "records": [...] }
        let decoder = JSONDecoder()
        if let queueResponse = try? decoder.decode(SonarrQueueResponse.self, from: data) {
            // Debug: Print first item details
            if let firstItem = queueResponse.records.first {
                print("🔍 First Sonarr item: id=\(firstItem.id), seriesId=\(firstItem.seriesId), series.id=\(firstItem.series?.id ?? -1), episode S\(firstItem.episode?.seasonNumber ?? -1)E\(firstItem.episode?.episodeNumber ?? -1)")
            }
            return queueResponse.records
        }

        // Fallback: try parsing as array directly
        return try decoder.decode([SonarrQueueItem].self, from: data)
    }

    func getActiveItems() async throws -> [SonarrQueueItem] {
        let allItems = try await getQueue()
        return allItems.filter { $0.isActive }
    }
}

// MARK: - Queue Response Wrapper

private struct SonarrQueueResponse: Codable {
    let records: [SonarrQueueItem]
}

// MARK: - Errors

enum SonarrError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Sonarr URL"
        case .invalidResponse:
            return "Invalid response from Sonarr"
        case .httpError(let code):
            return "Sonarr HTTP error: \(code)"
        case .authenticationFailed:
            return "Sonarr authentication failed - check API key"
        }
    }
}
