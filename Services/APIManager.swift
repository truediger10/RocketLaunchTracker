//
//  APIManager.swift
//  RocketLaunchTracker
//

import Foundation

/// Handles SpaceDevs API calls, caching, and enrichment.
actor APIManager: Sendable {
    static let shared = APIManager()
    
    // MARK: - Configuration
    private let baseURL = "https://ll.thespacedevs.com/2.2.0/launch/upcoming/"
    private let limit = 50
    private let mode = "list"
    private let maxRetries = 3
    private let initialRetryDelay: UInt64 = 500_000_000 // 0.5 sec
    private let timeoutInterval: TimeInterval = 15
    
    /// Important: we must request these fields so we get the provider name
    private let requiredFields = "id,name,net,status,launch_service_provider,rocket,mission,pad,image,status_name,rocket_name,agency_name,pad_name"
    
    // MARK: - Pagination
    private var nextURL: String? = nil
    
    // MARK: - Dependencies
    private let cache: CacheManager
    private let openAIService: OpenAIService
    private let urlSession: URLSession
    
    // MARK: - Initialization
    private init(cache: CacheManager = .shared,
                 openAIService: OpenAIService = .shared,
                 urlSession: URLSession = .shared) {
        self.cache = cache
        self.openAIService = openAIService
        self.urlSession = urlSession
        print("APIManager initialized with baseURL: \(baseURL)")
    }
    
    // MARK: - Public Methods
    
    func fetchLaunches() async throws -> [Launch] {
        let urlString = "\(baseURL)?limit=\(limit)&mode=\(mode)&fields=\(requiredFields)"
        let (launches, count) = try await fetchFromSpaceDevs(urlString: urlString)
        await cache.cacheLaunches(launches)
        print("Fetched \(launches.count) launches (Total count: \(count))")
        return launches
    }
    
    func fetchMoreLaunches() async throws -> [Launch]? {
        guard let next = nextURL else {
            print("No more pages to fetch.")
            return nil
        }
        let (launches, _) = try await fetchFromSpaceDevs(urlString: next)
        if launches.isEmpty {
            nextURL = nil
            return nil
        }
        await cache.cacheLaunches(launches)
        return launches
    }
    
    // MARK: - Private Methods
    
    private func fetchFromSpaceDevs(urlString: String) async throws -> ([Launch], Int) {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var attempt = 1
        var delay = initialRetryDelay
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        while attempt <= maxRetries {
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                request.timeoutInterval = timeoutInterval
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
                request.setValue("Token \(Config.shared.spaceDevsAPIKey)", forHTTPHeaderField: "Authorization")
                
                let (data, response) = try await urlSession.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    let decodedResponse = try decoder.decode(SpaceDevsResponse.self, from: data)
                    self.nextURL = decodedResponse.next
                    // Enrich launches concurrently
                    let enrichedLaunches = try await enrichLaunchesConcurrently(decodedResponse.results)
                    return (enrichedLaunches, decodedResponse.count)
                case 429:
                    throw APIError.rateLimited
                case 500...599:
                    throw APIError.serverError(code: httpResponse.statusCode)
                default:
                    throw APIError.serverError(code: httpResponse.statusCode)
                }
            } catch APIError.rateLimited {
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: delay)
                    delay = min(delay * 2, 8_000_000_000)
                    attempt += 1
                } else {
                    throw APIError.rateLimited
                }
            }
        }
        throw APIError.unknownError
    }
    
    private func enrichLaunchesConcurrently(_ spaceDevsLaunches: [SpaceDevsLaunch]) async throws -> [Launch] {
        try await withThrowingTaskGroup(of: Launch?.self) { group in
            for spaceDevsLaunch in spaceDevsLaunches {
                group.addTask {
                    // Convert from SpaceDevsLaunch to your app’s Launch model
                    var launch = spaceDevsLaunch.toAppLaunch()
                    
                    // Check if we already have an enrichment cached
                    if let cached = await self.cache.getCachedEnrichment(for: launch.id) {
                        launch.shortDescription = cached.shortDescription
                        launch.detailedDescription = cached.detailedDescription
                        launch.status = cached.status ?? launch.status
                        return launch
                    }
                    
                    // If not cached, try OpenAI enrichment
                    do {
                        let enrichment = try await self.openAIService.enrichLaunch(launch)
                        await self.cache.cacheEnrichment(enrichment, for: launch.id)
                        
                        // Update launch with GPT-provided fields
                        launch.shortDescription = enrichment.shortDescription
                        launch.detailedDescription = enrichment.detailedDescription
                        launch.status = enrichment.status ?? launch.status
                        return launch
                    } catch {
                        // If enrichment fails, return launch without GPT data
                        return launch
                    }
                }
            }
            
            var finalLaunches: [Launch] = []
            for try await enriched in group {
                if let l = enriched {
                    finalLaunches.append(l)
                }
            }
            return finalLaunches
        }
    }
}
