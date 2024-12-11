// Services/APIManager.swift

import Foundation

/// Manages API interactions, including fetching launches and handling enrichments.
actor APIManager {
    static let shared = APIManager()
    
    // MARK: - Constants
    private let baseURL = "https://ll.thespacedevs.com/2.3.0/launches/upcoming/"
    private let maxRetries = 3
    private let initialRetryDelay: UInt64 = 500_000_000 // 0.5 seconds
    
    // MARK: - Dependencies
    private let cache: CacheManager
    private let openAIService: OpenAIService
    private let urlSession: URLSession
    
    // MARK: - State
    private var nextURLString: String?
    private var isEnrichingBatch = false
    
    // MARK: - Initialization
    private init(
        cache: CacheManager = .shared,
        openAIService: OpenAIService = .shared,
        urlSession: URLSession = .shared
    ) {
        self.cache = cache
        self.openAIService = openAIService
        self.urlSession = urlSession
        
        print("APIManager initialized with baseURL: \(baseURL)")
    }
    
    // MARK: - Public Methods
    
    /// Fetches upcoming launches, utilizing cache if available.
    /// - Returns: An array of `Launch` objects.
    func fetchLaunches() async throws -> [Launch] {
        print("fetchLaunches() called")
        
        // Implement caching logic if needed
        // For simplicity, always fetch from API
        let launches = try await fetchFromSpaceDevs(urlString: baseURL)
        print("Fetched \(launches.count) launches from API")
        
        // Cache launches if needed
        // await cache.cacheLaunches(launches)
        
        return launches
    }
    
    /// Fetches additional launches using the next URL if available.
    /// - Returns: An optional array of `Launch` objects.
    func fetchMoreLaunches() async throws -> [Launch]? {
        guard let nextURL = nextURLString else {
            print("No more launches to fetch.")
            return nil
        }
        
        print("fetchMoreLaunches() called with URL: \(nextURL)")
        let launches = try await fetchFromSpaceDevs(urlString: nextURL)
        print("Fetched \(launches.count) more launches from API")
        
        // Cache additional launches if needed
        // await cache.cacheLaunches(launches)
        
        return launches
    }
    
    // MARK: - Private Methods
    
    /// Fetches launches from the SpaceDevs API with retry logic.
    /// - Parameter urlString: The URL string to fetch data from.
    /// - Returns: An array of `Launch` objects.
    private func fetchFromSpaceDevs(urlString: String) async throws -> [Launch] {
        print("Fetching from SpaceDevs API with URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        var attempt = 1
        var delay = initialRetryDelay
        
        // Configure JSONDecoder with appropriate date decoding strategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        while attempt <= maxRetries {
            do {
                let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
                let (data, response) = try await urlSession.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response received from URL: \(urlString)")
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let decodedResponse = try decoder.decode(SpaceDevsResponse.self, from: data)
                        self.nextURLString = decodedResponse.next
                        print("Received successful response with status code: \(httpResponse.statusCode)")
                        return decodedResponse.results
                    } catch {
                        // Print raw JSON for debugging
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("Decoding failed. Raw JSON:")
                            print(jsonString)
                        }
                        print("Decoding error: \(error)")
                        throw APIError.decodingError(error)
                    }
                case 429:
                    print("Rate limited by API with status code: 429")
                    throw APIError.rateLimited
                default:
                    print("Server error with status code: \(httpResponse.statusCode)")
                    throw APIError.serverError(code: httpResponse.statusCode)
                }
            } catch APIError.rateLimited {
                if attempt == maxRetries {
                    print("Max retries reached due to rate limiting.")
                    throw APIError.rateLimited
                }
                print("Rate limited. Retrying after \(Double(delay) / 1_000_000_000) seconds...")
                try await Task.sleep(nanoseconds: delay)
                delay *= 2
                attempt += 1
            } catch APIError.decodingError(let decodingError) {
                print("Decoding error on attempt \(attempt): \(decodingError)")
                // Decide whether to retry on decoding errors
                // Here, we'll not retry and throw the error
                throw APIError.decodingError(decodingError)
            } catch {
                if attempt == maxRetries {
                    print("Max retries reached. Throwing error.")
                    throw APIError.networkError(error)
                }
                print("Attempt \(attempt) failed with error: \(error). Retrying after \(Double(delay) / 1_000_000_000) seconds...")
                try await Task.sleep(nanoseconds: delay)
                delay *= 2
                attempt += 1
            }
        }
        
        throw APIError.unknownError
    }
}
