//
//  LidarrClient.swift
//  Arrstatus
//

import Foundation

@Observable
class LidarrClient {
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

    func getQueue() async throws -> [LidarrQueueItem] {
        guard let url = URL(string: "\(baseURL)/api/v1/queue?includeArtist=true&includeAlbum=true") else {
            throw LidarrError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LidarrError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw LidarrError.authenticationFailed
            }
            throw LidarrError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        if let queueResponse = try? decoder.decode(LidarrQueueResponse.self, from: data) {
            return queueResponse.records
        }
        return try decoder.decode([LidarrQueueItem].self, from: data)
    }

    func getActiveItems() async throws -> [LidarrQueueItem] {
        let allItems = try await getQueue()
        return allItems.filter { $0.isActive }
    }
}

// MARK: - Queue Response Wrapper

private struct LidarrQueueResponse: Codable {
    let records: [LidarrQueueItem]
}

// MARK: - Errors

enum LidarrError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Lidarr URL"
        case .invalidResponse: return "Invalid response from Lidarr"
        case .httpError(let code): return "Lidarr HTTP error: \(code)"
        case .authenticationFailed: return "Lidarr authentication failed - check API key"
        }
    }
}
