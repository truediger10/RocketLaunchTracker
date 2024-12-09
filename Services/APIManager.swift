import Foundation

/// Manages API interactions, including fetching launches and handling enrichments.
actor APIManager {
    static let shared = APIManager()
    private let baseURL = "https://ll.thespacedevs.com/2.3.0/launches/upcoming/?limit=50"
    private let maxRetries = 3
    private let initialRetryDelay: UInt64 = 500_000_000 // 0.5 seconds
    
    private let cache: CacheManager
    private let openAIService: OpenAIService
    private let urlSession: URLSession
    private let enrichmentQueue: TaskQueue
    
    private var nextURLString: String?
    private var isEnrichingBatch = false
    
    private init(
        cache: CacheManager = .shared,
        openAIService: OpenAIService = .shared,
        urlSession: URLSession = .shared,
        maxConcurrentEnrichments: Int = 5
    ) {
        self.cache = cache
        self.openAIService = openAIService
        self.urlSession = urlSession
        self.enrichmentQueue = TaskQueue(maxConcurrent: maxConcurrentEnrichments)
        
        print("APIManager initialized with baseURL: \(baseURL)")
    }
    
    /// Fetches upcoming launches, utilizing cache if available.
    /// - Returns: An array of `Launch` objects.
    func fetchLaunches() async throws -> [Launch] {
        print("fetchLaunches() called")
        
        if let cached = await cache.getCachedLaunches() {
            print("Fetched launches from cache. Count: \(cached.count)")
            startBackgroundEnrichment(for: cached)
            return cached
        }
        
        print("Fetching launches from SpaceDevs API")
        let response = try await fetchFromSpaceDevs(urlString: baseURL)
        let launches = response.results.map { $0.toAppLaunch() }
        print("Fetched \(launches.count) launches from API")
        
        await cache.cacheLaunches(launches)
        print("Cached launches")
        startBackgroundEnrichment(for: launches)
        
        return launches
    }
    
    /// Fetches additional launches using the next URL if available.
    /// - Returns: An optional array of `Launch` objects.
    func fetchMoreLaunches() async throws -> [Launch]? {
        guard let nextURL = nextURLString else {
            print("No more launches to fetch.")
            return nil
        }
        
        print("Fetching more launches from URL: \(nextURL)")
        let response = try await fetchFromSpaceDevs(urlString: nextURL)
        let launches = response.results.map { $0.toAppLaunch() }
        print("Fetched \(launches.count) more launches from API")
        startBackgroundEnrichment(for: launches)
        
        return launches
    }
    
    /// Initiates background enrichment for a batch of launches.
    /// - Parameter launches: The launches to enrich.
    private func startBackgroundEnrichment(for launches: [Launch]) {
        print("Starting background enrichment for \(launches.count) launches")
        Task.detached(priority: .background) {
            await self.enrichUnenrichedLaunches(launches)
        }
    }
    
    /// Fetches launches from the SpaceDevs API with retry logic.
    /// - Parameter urlString: The URL string to fetch data from.
    /// - Returns: A `SpaceDevsResponse` object.
    private func fetchFromSpaceDevs(urlString: String) async throws -> SpaceDevsResponse {
        print("Fetching from SpaceDevs API with URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await fetchWithRetry(url: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response received from URL: \(urlString)")
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let decodedResponse = try JSONDecoder().decode(SpaceDevsResponse.self, from: data)
                self.nextURLString = decodedResponse.next
                print("Received successful response with status code: \(httpResponse.statusCode)")
                return decodedResponse
            case 429:
                print("Rate limited by API with status code: 429")
                throw APIError.rateLimited
            default:
                print("Server error with status code: \(httpResponse.statusCode)")
                throw APIError.serverError(code: httpResponse.statusCode)
            }
        } catch {
            print("Error fetching from SpaceDevs API: \(error)")
            throw error
        }
    }
    
    /// Enriches unenriched launches by fetching additional data.
    /// - Parameter launches: The launches to enrich.
    private func enrichUnenrichedLaunches(_ launches: [Launch]) async {
        guard !isEnrichingBatch else {
            print("Enrichment already in progress. Skipping new batch.")
            return
        }
        isEnrichingBatch = true
        defer { isEnrichingBatch = false }
        
        var unenriched: [Launch] = []
        for launch in launches {
            if await cache.getCachedEnrichment(for: launch.id) == nil {
                unenriched.append(launch)
            }
        }
        
        print("Found \(unenriched.count) unenriched launches to process")
        
        await withTaskGroup(of: Void.self) { group in
            for launch in unenriched {
                group.addTask {
                    await self.enrichLaunch(launch)
                }
            }
        }
        
        print("Completed enrichment for batch of launches")
    }
    
    /// Enriches a single launch by fetching additional data from OpenAI.
    /// - Parameter launch: The launch to enrich.
    private func enrichLaunch(_ launch: Launch) async {
        print("Starting enrichment for launch ID: \(launch.id)")
        do {
            try await enrichmentQueue.enqueue {
                let enrichment = try await self.openAIService.enrichLaunch(launch)
                await self.cache.cacheEnrichment(enrichment, for: launch.id)
                
                NotificationCenter.default.post(
                    name: .launchEnrichmentUpdated,
                    object: nil,
                    userInfo: ["launchId": launch.id]
                )
                print("Enrichment completed for launch ID: \(launch.id)")
            }
        } catch {
            print("Failed to enrich launch ID: \(launch.id) with error: \(error)")
            // Error handled silently as enrichment is non-critical
        }
    }
    
    /// Fetches data from a URL with retry logic.
    /// - Parameter url: The URL to fetch data from.
    /// - Returns: A tuple containing `Data` and `URLResponse`.
    private func fetchWithRetry(url: URL) async throws -> (Data, URLResponse) {
        var delay = initialRetryDelay
        var attempt = 1
        
        while true {
            do {
                print("Attempt \(attempt) to fetch URL: \(url.absoluteString)")
                let request = URLRequest(url: url,
                                         cachePolicy: .returnCacheDataElseLoad,
                                         timeoutInterval: 30)
                let result = try await urlSession.data(for: request)
                print("Successfully fetched data on attempt \(attempt)")
                return result
            } catch {
                print("Attempt \(attempt) failed with error: \(error)")
                guard attempt < maxRetries else {
                    print("Max retries reached. Throwing error.")
                    throw APIError.networkError(error)
                }
                
                print("Retrying after \(delay / 1_000_000_000) seconds...")
                try await Task.sleep(nanoseconds: delay)
                delay *= 2
                attempt += 1
            }
        }
    }
}
