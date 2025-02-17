//
//  APIManager.swift
//  RocketLaunchTracker
//
//  Bare-bones fetch from The Space Devs (no caching or enrichment).
//  Handles pagination by storing nextURL from the response.
//
import Foundation

actor APIManager: Sendable {
    static let shared = APIManager()
    
    // MARK: - Configuration
    private let baseURL = "https://ll.thespacedevs.com/2.3.0/launches/upcoming"
    /// Use a small limit to force multiple pages if you want. e.g. 10 or 25
    private let limit = 50
    private let mode = "normal"
    private let maxRetries = 3
    private let initialRetryDelay: UInt64 = 500_000_000
    private let timeoutInterval: TimeInterval = 15
    
    // MARK: - Pagination
    private var nextURL: String? = nil
    
    // Dependencies
    private let urlSession: URLSession
    
    private init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        print("APIManager initialized with baseURL: \(baseURL)")
    }
    
    // MARK: - Public Methods
    
    /// Fetches the first page of upcoming launches
    func fetchLaunches() async throws -> [Launch] {
        let urlString = "\(baseURL)?limit=\(limit)&mode=\(mode)"
        let (launches, _) = try await fetchFromSpaceDevs(urlString: urlString)
        return launches
    }
    
    /// Fetches the next page, if available. Returns nil if no next page.
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
                
                // If you have a token:
                // request.setValue("Token <YOUR_API_TOKEN>", forHTTPHeaderField: "Authorization")
                
                let (data, response) = try await urlSession.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    let decoded = try decoder.decode(SpaceDevsResponse.self, from: data)
                    
                    // Store next page
                    self.nextURL = decoded.next
                    
                    // Map SpaceDevsLaunch → your Launch struct
                    let mapped = decoded.results.compactMap { $0.toAppLaunch() }
                    return (mapped, decoded.count)
                    
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
}
