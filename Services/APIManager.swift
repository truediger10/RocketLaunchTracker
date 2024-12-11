// Services/APIManager.swift

import Foundation

/**
 Manages API interactions, including fetching launches and handling enrichments.
 
 Utilizes a shared instance for centralized API management.
 */
actor APIManager {
    static let shared = APIManager()
    
    // MARK: - Constants
    private enum Constants {
        static let baseURL = "https://ll.thespacedevs.com/2.3.0/launches/upcoming/"
        static let limit = 10
        static let maxRetries = 3
        static let initialRetryDelay: TimeInterval = 0.5 // in seconds
        
        // Exponential backoff factors
        static let backoffFactor: Double = 2.0
        static let maxRetryDelay: TimeInterval = 60.0 // 1 minute
    }
    
    // MARK: - Properties
    private let cache: CacheManager
    private let openAIService: OpenAIService
    private let urlSession: URLSession
    private let enrichmentQueue: TaskQueue
    
    private var nextURLString: String?
    private var updateTimers: [String: [Task<Void, Never>]] = [:]
    private var loadedLaunches: Set<String> = []
    
    // MARK: - Initialization
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
        
        // Log the SpaceDevs API Key
        print("🔑 SpaceDevs API Key: \(Config.shared.spaceDevsAPIKey)")
    }
    
    // MARK: - Public Methods
    
    /// Fetches initial batch of launches for quick display
    func fetchInitialLaunches() async throws -> [Launch] {
        let url = "\(Constants.baseURL)?limit=\(Constants.limit)"
        let response = try await fetchFromSpaceDevs(urlString: url)
        let launches = response.results.map { convertToAppLaunch($0) }
        
        // Cache and start background tasks
        await cache.cacheLaunches(launches)
        setupUpdateTimers(for: launches)
        startBackgroundEnrichment(for: launches)
        
        // Update nextURLString for pagination
        nextURLString = response.next
        return launches
    }
    
    /// Fetches remaining launches after initial batch
    func fetchRemainingLaunches() async throws -> [Launch] {
        guard let nextURL = nextURLString else { return [] }
        
        let response = try await fetchFromSpaceDevs(urlString: nextURL)
        let launches = response.results.map { convertToAppLaunch($0) }
        
        await cache.cacheLaunches(launches)
        setupUpdateTimers(for: launches)
        startBackgroundEnrichment(for: launches)
        
        // Update nextURLString for further pagination
        nextURLString = response.next
        return launches
    }
    
    /// Fetches all launches, utilizing cached data if available
    func fetchLaunches() async throws -> [Launch] {
        // Try to get cached launches first
        if let cachedLaunches = await cache.getCachedLaunches(), !cachedLaunches.isEmpty {
            print("Using cached launches. Count: \(cachedLaunches.count)")
            // Start background fetching of remaining launches
            Task.detached {
                do {
                    let remaining = try await self.fetchRemainingLaunches()
                    print("Fetched remaining launches in background. Count: \(remaining.count)")
                } catch {
                    print("Failed to fetch remaining launches in background: \(error)")
                }
            }
            return cachedLaunches
        }
        
        // If no cached launches, fetch initial batch
        return try await fetchInitialLaunches()
    }
    
    /// Fetches a specific launch by ID
    func fetchLaunch(by id: String) async throws -> Launch? {
        let url = "\(Constants.baseURL)\(id)/"
        return try await fetchSingleLaunch(urlString: url)
    }
    
    /// Updates a specific launch
    func updateLaunch(_ launchId: String) async throws -> Launch? {
        return try await fetchLaunch(by: launchId)
    }
    
    /// Fetches more launches, used for pagination
    func fetchMoreLaunches() async throws -> [Launch] {
        return try await fetchRemainingLaunches()
    }
    
    // MARK: - Private Methods
    
    /// Sets up update timers for launches
    private func setupUpdateTimers(for launches: [Launch]) {
        for launch in launches {
            setupUpdateTimer(for: launch)
        }
    }
    
    /// Sets up update timers for a specific launch
    private func setupUpdateTimer(for launch: Launch) {
        // Cancel existing timers if any
        if let existingTimers = updateTimers[launch.id] {
            for timer in existingTimers {
                timer.cancel()
            }
        }
        
        var timers: [Task<Void, Never>] = []
        
        let oneWeekBefore = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: launch.launchDate)
        let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: launch.launchDate)
        let dayOfLaunch = launch.launchDate
        
        // Schedule once a week before launch
        if let date = oneWeekBefore, date > Date() {
            let timer = scheduleUpdate(at: date, for: launch)
            timers.append(timer)
        }
        
        // Schedule once a day before launch
        if let date = oneDayBefore, date > Date() {
            let timer = scheduleUpdate(at: date, for: launch)
            timers.append(timer)
        }
        
        // Schedule once on the day of launch
        if dayOfLaunch > Date() {
            let timer = scheduleUpdate(at: dayOfLaunch, for: launch)
            timers.append(timer)
        }
        
        updateTimers[launch.id] = timers
    }
    
    /// Schedules an update task at a specific date for a launch
    private func scheduleUpdate(at date: Date, for launch: Launch) -> Task<Void, Never> {
        let waitTime = date.timeIntervalSinceNow
        guard waitTime > 0 else { return Task { } } // If the time has already passed, skip
        
        return Task {
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            do {
                if let updatedLaunch = try await updateLaunch(launch.id) {
                    NotificationCenter.default.post(
                        name: .launchDataUpdated,
                        object: nil,
                        userInfo: ["launchId": launch.id, "launch": updatedLaunch]
                    )
                    print("🔄 Launch data updated for ID: \(launch.id) at \(Date())")
                }
            } catch {
                print("❌ Failed to update launch \(launch.id) at \(Date()): \(error.localizedDescription)")
            }
        }
    }
    
    /// Starts background enrichment for launches
    private func startBackgroundEnrichment(for launches: [Launch]) {
        Task.detached(priority: .background) {
            await self.enrichUnenrichedLaunches(launches)
        }
    }
    
    /// Enriches launches that lack enriched data
    private func enrichUnenrichedLaunches(_ launches: [Launch]) async {
        var unenrichedLaunches: [Launch] = []
        
        for launch in launches {
            if await cache.getCachedEnrichment(for: launch.id) == nil {
                unenrichedLaunches.append(launch)
            }
        }
        
        guard !unenrichedLaunches.isEmpty else {
            print("✅ All launches already enriched.")
            return
        }
        
        for launch in unenrichedLaunches {
            do {
                try await enrichmentQueue.enqueue {
                    do {
                        let enrichment = try await self.openAIService.enrichLaunch(launch)
                        await self.cache.cacheEnrichment(enrichment, for: launch.id)
                        
                        NotificationCenter.default.post(
                            name: .launchEnrichmentUpdated,
                            object: nil,
                            userInfo: ["launchId": launch.id]
                        )
                        
                        print("✅ Enriched launch with ID: \(launch.id)")
                    } catch {
                        print("❌ Failed to enrich launch \(launch.id): \(error.localizedDescription)")
                    }
                }
            } catch {
                print("❌ Unable to enqueue enrichment for launch \(launch.id): \(error.localizedDescription)")
            }
        }
    }
    
    /// Fetches data from SpaceDevs API
    private func fetchFromSpaceDevs(urlString: String, retryCount: Int = 0) async throws -> SpaceDevsResponse {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let spaceDevsAPIKey = Config.shared.spaceDevsAPIKey
        guard !spaceDevsAPIKey.isEmpty else {
            throw APIError.invalidAPIKey
        }
        request.setValue("Bearer \(spaceDevsAPIKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            try validateResponse(response, data: data)
            let decoded = try JSONDecoder().decode(SpaceDevsResponse.self, from: data)
            return decoded
        } catch let error as APIError {
            switch error {
            case .rateLimited(let retryAfter, _):
                if retryCount < Constants.maxRetries {
                    let exponentialDelay = Constants.initialRetryDelay * pow(Constants.backoffFactor, Double(retryCount))
                    let jitter = Double.random(in: 0...1)
                    let delay = min(retryAfter, min(exponentialDelay + jitter, Constants.maxRetryDelay))
                    
                    print("⚠️ Rate limited. Retrying after \(delay) seconds.")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await fetchFromSpaceDevs(urlString: urlString, retryCount: retryCount + 1)
                }
                throw error
            default:
                throw error
            }
        }
    }
    
    /// Fetches a single launch
    private func fetchSingleLaunch(urlString: String) async throws -> Launch? {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let spaceDevsAPIKey = Config.shared.spaceDevsAPIKey
        guard !spaceDevsAPIKey.isEmpty else {
            throw APIError.invalidAPIKey
        }
        request.setValue("Bearer \(spaceDevsAPIKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        try validateResponse(response, data: data)
        
        let spaceDevsLaunch = try JSONDecoder().decode(SpaceDevsLaunch.self, from: data)
        let launch = convertToAppLaunch(spaceDevsLaunch)
        
        if let enrichment = await cache.getCachedEnrichment(for: launch.id) {
            let enrichedLaunch = Launch(
                id: launch.id,
                name: launch.name,
                launchDate: launch.launchDate,
                status: launch.status,
                rocketName: launch.rocketName,
                provider: launch.provider,
                location: launch.location,
                imageURL: launch.imageURL,
                shortDescription: enrichment.shortDescription,
                detailedDescription: enrichment.detailedDescription,
                orbit: launch.orbit,
                wikiURL: launch.wikiURL,
                twitterURL: nil,
                badges: nil
            )
            await cache.cacheLaunches([enrichedLaunch])
            return enrichedLaunch
        }
        
        await cache.cacheLaunches([launch])
        return launch
    }
    
    /// Converts SpaceDevsLaunch to Launch model
    private func convertToAppLaunch(_ spaceDevsLaunch: SpaceDevsLaunch) -> Launch {
        let dateFormatter = ISO8601DateFormatter()
        let launchDate = dateFormatter.date(from: spaceDevsLaunch.net) ?? Date()
        let mappedStatus = LaunchStatus(fromAPIStatus: spaceDevsLaunch.status.name)
        
        return Launch(
            id: spaceDevsLaunch.id,
            name: spaceDevsLaunch.name,
            launchDate: launchDate,
            status: mappedStatus,
            rocketName: spaceDevsLaunch.rocket.configuration.fullName,
            provider: spaceDevsLaunch.launchServiceProvider.name,
            location: spaceDevsLaunch.pad.location.name,
            imageURL: spaceDevsLaunch.image?.imageURL,
            shortDescription: nil,
            detailedDescription: nil,
            orbit: spaceDevsLaunch.orbit?.name,
            wikiURL: spaceDevsLaunch.pad.wikiURL,
            twitterURL: nil,
            badges: nil
        )
    }
    
    /// Validates response and handles common error cases
    private func validateResponse(_ response: URLResponse?, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 429:
                if let retryAfter = parseRetryAfter(from: data) {
                    throw APIError.rateLimited(retryAfter: retryAfter, message: "Rate limit exceeded.")
                } else {
                    throw APIError.rateLimited(retryAfter: Constants.initialRetryDelay, message: "Rate limit exceeded.")
                }
            case 401:
                throw APIError.invalidAPIKey
            default:
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw APIError.serverError(code: httpResponse.statusCode, message: message)
            }
        }
    }
    
    /// Parses retry-after time from response data
    private func parseRetryAfter(from data: Data) -> TimeInterval? {
        struct ErrorResponse: Codable {
            let detail: String
        }
        
        do {
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            let pattern = #"Expected available in (\d+) seconds."#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: errorResponse.detail, options: [], range: NSRange(location: 0, length: errorResponse.detail.utf16.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: errorResponse.detail),
               let seconds = TimeInterval(errorResponse.detail[range]) {
                return seconds
            }
        } catch {
            print("❌ Failed to parse error response: \(error.localizedDescription)")
        }
        return nil
    }
}
