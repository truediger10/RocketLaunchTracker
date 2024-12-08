import Foundation

/// A manager for fetching data from the SpaceDevs API and enriching it via OpenAI.
/// Includes pagination, caching, and retries.
actor APIManager {
    static let shared = APIManager()
    
    // Base URL for initial fetch. We'll rely on `next` from the API for pagination.
    private let baseURL = "https://ll.thespacedevs.com/2.3.0/launches/upcoming/?limit=30"
    private let cache: CacheManager
    private let openAIService: OpenAIService
    private let urlSession: URLSession
    
    private let maxRetries = 3
    
    // Track pagination
    private var nextURLString: String? = nil
    
    private init(cache: CacheManager = .shared,
                 openAIService: OpenAIService = .shared,
                 urlSession: URLSession = .shared) {
        self.cache = cache
        self.openAIService = openAIService
        self.urlSession = urlSession
    }
    
    /// Fetches launches (first page by default) with caching, enrichment, and retry.
    func fetchLaunches() async throws -> [Launch] {
        return try await fetchLaunches(fromURL: baseURL)
    }
    
    /// Fetches the next page of launches if available.
    func fetchMoreLaunches() async throws -> [Launch]? {
        guard let nextURL = nextURLString else {
            print("ℹ️ No more launches to fetch (no next URL).")
            return nil
        }
        return try await fetchLaunches(fromURL: nextURL)
    }
    
    /// Performs the actual fetch operation from a given URL. Handles caching, enrichment, and retry.
    private func fetchLaunches(fromURL urlString: String) async throws -> [Launch] {
        print("🚀 Attempting to fetch launches from \(urlString)...")
        
        // If this is the first page, attempt to use cached enriched data first.
        if urlString == baseURL {
            if let cachedLaunches = await cache.getCachedLaunches() {
                print("📦 Using cached launches (\(cachedLaunches.count))")
                // If enriched cached data is available, return immediately.
                return cachedLaunches
            }
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        // Perform request with retries and exponential backoff.
        let (data, response) = try await fetchDataWithRetry(url: url, retries: maxRetries)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimited
            }
            throw APIError.serverError(code: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let spaceDevsResponse = try decoder.decode(SpaceDevsResponse.self, from: data)
        
        self.nextURLString = spaceDevsResponse.next // Save next page URL if any
        
        print("✅ Decoded \(spaceDevsResponse.results.count) launches from API response")
        
        var enrichedLaunches: [Launch] = []
        
        for spaceDevsLaunch in spaceDevsResponse.results {
            if let cachedEnrichment = await cache.getCachedEnrichment(for: spaceDevsLaunch.id) {
                print("🧠 Using cached enrichment for launch \(spaceDevsLaunch.id)")
                enrichedLaunches.append(spaceDevsLaunch.toAppLaunch(withEnrichment: cachedEnrichment))
            } else {
                // Attempt to enrich the launch data via OpenAI.
                do {
                    let enrichment = try await openAIService.enrichLaunch(spaceDevsLaunch)
                    await cache.cacheEnrichment(enrichment, for: spaceDevsLaunch.id)
                    enrichedLaunches.append(spaceDevsLaunch.toAppLaunch(withEnrichment: enrichment))
                } catch {
                    print("⚠️ Enrichment failed for launch \(spaceDevsLaunch.id): \(error)")
                    // Fallback: use the original data without enrichment.
                    enrichedLaunches.append(spaceDevsLaunch.toAppLaunch())
                }
            }
        }
        
        // Cache the combined result if this is the first page.
        if urlString == baseURL {
            await cache.cacheLaunches(enrichedLaunches)
        }
        
        print("📱 Returning \(enrichedLaunches.count) enriched launches")
        return enrichedLaunches
    }
    
    /// A helper method to fetch data with multiple retries and exponential backoff.
    private func fetchDataWithRetry(url: URL, retries: Int) async throws -> (Data, URLResponse) {
        var delay: UInt64 = 500_000_000 // 0.5 seconds
        var attempt = 1
        while true {
            do {
                let (data, response) = try await urlSession.data(for: URLRequest(url: url))
                print("🔵 Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1) on attempt \(attempt)")
                return (data, response)
            } catch {
                if attempt < retries {
                    print("🔄 Network request failed (attempt \(attempt)): \(error). Retrying in \(delay/1_000_000_000)s...")
                    try await Task.sleep(nanoseconds: delay)
                    delay *= 2
                    attempt += 1
                } else {
                    print("❌ Network request failed after \(attempt) attempts: \(error)")
                    throw APIError.networkError(error)
                }
            }
        }
    }
}
