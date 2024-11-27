import Foundation

protocol APIManagerProtocol {
    func fetchUpcomingLaunches(limit: Int, offset: Int) async throws -> SpaceDevsResponse
    func enrichLaunchData(launch: Launch) async throws -> LaunchEnrichment
    func fetchLaunchDetails(id: String) async throws -> Launch
}

class APIManager: APIManagerProtocol {
    // MARK: - Properties
    private let session: URLSession
    private let spaceDevsBaseURL = "https://ll.thespacedevs.com/2.3.0"
    private let openAIService: OpenAIServiceProtocol
    private let cache = URLCache.shared
    private let requestTimeout: TimeInterval = 30

    // MARK: - Initialization
    init(session: URLSession = .shared,
         openAIService: OpenAIServiceProtocol = OpenAIService.shared) {
        self.session = session
        self.openAIService = openAIService
        setupURLCache()
    }

    // MARK: - Private Setup
    private func setupURLCache() {
        cache.memoryCapacity = 50 * 1024 * 1024  // 50 MB
        cache.diskCapacity = 100 * 1024 * 1024   // 100 MB
    }

    // MARK: - API Methods
    /// Fetches upcoming launches from SpaceDevs API
    func fetchUpcomingLaunches(limit: Int, offset: Int) async throws -> SpaceDevsResponse {
        try checkRateLimit()
        
        guard var urlComponents = URLComponents(string: "\(spaceDevsBaseURL)/launch/upcoming/") else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url, timeoutInterval: requestTimeout)
        request.httpMethod = "GET"
        request.setValue("Token \(Config.shared.spaceDevsAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let cachedResponse = cache.cachedResponse(for: request),
           let httpResponse = cachedResponse.response as? HTTPURLResponse,
           httpResponse.statusCode == 200 {
            return try decodeResponse(cachedResponse.data)
        }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        // Cache the successful response
        if let httpResponse = response as? HTTPURLResponse {
            let cachedResponse = CachedURLResponse(
                response: httpResponse,
                data: data,
                userInfo: nil,
                storagePolicy: .allowed
            )
            cache.storeCachedResponse(cachedResponse, for: request)
        }
        
        return try decodeResponse(data)
    }

    /// Fetches detailed information for a specific launch
    func fetchLaunchDetails(id: String) async throws -> Launch {
        try checkRateLimit()
        
        guard let url = URL(string: "\(spaceDevsBaseURL)/launch/\(id)/") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url, timeoutInterval: requestTimeout)
        request.httpMethod = "GET"
        request.setValue("Token \(Config.shared.spaceDevsAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let spaceDevsLaunch = try decodeResponse(data) as SpaceDevsLaunch
        return spaceDevsLaunch.toAppLaunch(withEnrichment: nil)
    }

    /// Enriches launch data using OpenAI
    func enrichLaunchData(launch: Launch) async throws -> LaunchEnrichment {
        try checkRateLimit()
        return try await openAIService.enrichLaunch(launch: launch)
    }

    // MARK: - Private Helper Methods
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.serverError(code: httpResponse.statusCode)
        }
    }
    
    private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Response Rate Limiting
    private static let rateLimitInterval: TimeInterval = 1.0
    private static let maxRequestsPerInterval = 10
    private var currentRequests = 0
    private var lastRequestTime = Date()
    
    private func checkRateLimit() throws {
        let now = Date()
        if now.timeIntervalSince(lastRequestTime) >= APIManager.rateLimitInterval {
            currentRequests = 0
            lastRequestTime = now
        }
        
        guard currentRequests < APIManager.maxRequestsPerInterval else {
            throw APIError.rateLimited
        }
        
        currentRequests += 1
    }
}
