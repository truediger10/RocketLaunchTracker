// Services/APIManager.swift

import Foundation

actor APIManager: Sendable {
    // MARK: - Shared Instance
    static let shared = APIManager()
    
    // MARK: - Constants
    private let baseURL = "https://ll.thespacedevs.com/2.3.0/launches/upcoming/?limit=20&offset=0"
    private let maxRetries = 3
    private let initialRetryDelay: UInt64 = 500_000_000 // 0.5 seconds
    private let timeoutInterval: TimeInterval = 15
    
    // MARK: - Update Schedule Constants
    private enum UpdateSchedule {
        static let weekBefore: TimeInterval = 7 * 24 * 60 * 60  // 1 week
        static let dayBefore: TimeInterval = 24 * 60 * 60       // 1 day
        static let dayOf: TimeInterval = 60 * 60                // Every hour on launch day
    }
    
    // MARK: - Dependencies
    private let cache: CacheManager
    private let openAIService: OpenAIService
    private let urlSession: URLSession
    
    // MARK: - State
    private var nextURLString: String?
    private var scheduledUpdateTasks: [String: Task<Void, Never>] = [:]
    
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
    func fetchLaunches() async throws -> [Launch] {
        print("fetchLaunches() called")
        let launches = try await fetchFromSpaceDevs(urlString: baseURL)
        await cacheLaunches(launches)
        scheduleUpdatesForAllLaunches(launches)
        print("Fetched \(launches.count) launches from API")
        return launches
    }
    
    func fetchMoreLaunches() async throws -> [Launch]? {
        guard let nextURL = nextURLString else {
            print("No more launches to fetch.")
            return nil
        }
        
        print("fetchMoreLaunches() called with URL: \(nextURL)")
        let launches = try await fetchFromSpaceDevs(urlString: nextURL)
        await cacheLaunches(launches)
        scheduleUpdatesForAllLaunches(launches)
        print("Fetched \(launches.count) more launches from API")
        return launches
    }
    
    // MARK: - Private Methods
    private func fetchFromSpaceDevs(urlString: String) async throws -> [Launch] {
        print("Fetching from SpaceDevs API with URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
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
                
                let (data, response) = try await urlSession.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let decodedResponse = try decoder.decode(SpaceDevsResponse.self, from: data)
                        self.nextURLString = decodedResponse.next
                        print("Received successful response with status code: \(httpResponse.statusCode)")
                        return try await enrichLaunchesConcurrently(decodedResponse.results)
                    } catch {
                        print("Decoding error: \(error)")
                        throw APIError.decodingError(error)
                    }
                case 429:
                    throw APIError.rateLimited
                case 500...599:
                    throw APIError.serverError(code: httpResponse.statusCode)
                default:
                    throw APIError.serverError(code: httpResponse.statusCode)
                }
            } catch let urlError as URLError where urlError.code == .cancelled {
                print("Request was cancelled")
                throw APIError.networkError(urlError)
            } catch let error as APIError {
                switch error {
                case .rateLimited where attempt < maxRetries:
                    print("Rate limited. Retrying after \(Double(delay) / 1_000_000_000) seconds...")
                    try await Task.sleep(nanoseconds: delay)
                    delay *= 2
                    attempt += 1
                    continue
                case .decodingError, .invalidResponse:
                    throw error
                default:
                    if attempt >= maxRetries {
                        throw error
                    }
                    print("Retrying after error: \(error)")
                    try await Task.sleep(nanoseconds: delay)
                    delay *= 2
                    attempt += 1
                }
            }
        }
        
        throw APIError.unknownError
    }
    
    private func enrichLaunchesConcurrently(_ spaceDevsLaunches: [SpaceDevsLaunch]) async throws -> [Launch] {
        try await withThrowingTaskGroup(of: Launch?.self) { group in
            for spaceDevsLaunch in spaceDevsLaunches {
                group.addTask {
                    // Safely unwrap the optional launch.
                    guard var launch = spaceDevsLaunch.toAppLaunch(withEnrichment: nil) else {
                        return nil
                    }
                    
                    if let cachedEnrichment = await self.cache.getCachedEnrichment(for: launch.id) {
                        launch.shortDescription = cachedEnrichment.shortDescription
                        launch.detailedDescription = cachedEnrichment.detailedDescription
                        launch.status = cachedEnrichment.status ?? launch.status
                        return launch
                    }
                    
                    do {
                        let enrichedData = try await self.openAIService.enrichLaunch(launch)
                        await self.cache.cacheEnrichment(enrichedData, for: launch.id)
                        
                        launch.shortDescription = enrichedData.shortDescription
                        launch.detailedDescription = enrichedData.detailedDescription
                        launch.status = enrichedData.status ?? launch.status
                        
                        return launch
                    } catch {
                        print("Failed to enrich launch ID: \(launch.id) with error: \(error)")
                        return launch
                    }
                }
            }
            
            var enrichedLaunches: [Launch] = []
            for try await enrichedLaunch in group {
                if let enrichedLaunch = enrichedLaunch {
                    enrichedLaunches.append(enrichedLaunch)
                }
            }
            return enrichedLaunches
        }
    }
    
    // MARK: - Update Scheduling Methods
    private func scheduleUpdatesForLaunch(_ launch: Launch) {
        guard let launchDate = launch.net else { return }
        
        // Cancel existing update tasks for this launch
        scheduledUpdateTasks[launch.id]?.cancel()
        
        let now = Date()
        let weekBeforeDate = launchDate.addingTimeInterval(-UpdateSchedule.weekBefore)
        let dayBeforeDate = launchDate.addingTimeInterval(-UpdateSchedule.dayBefore)
        
        if weekBeforeDate > now {
            scheduleUpdate(for: launch, at: weekBeforeDate)
        }
        
        if dayBeforeDate > now {
            scheduleUpdate(for: launch, at: dayBeforeDate)
        }
        
        if launchDate > now {
            scheduleUpdate(for: launch, at: launchDate)
        }
    }
    
    private func scheduleUpdate(for launch: Launch, at date: Date) {
        let task = Task {
            let interval = date.timeIntervalSince(Date())
            if interval > 0 {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if !Task.isCancelled {
                    try? await checkForUpdates(forLaunch: launch)
                }
            }
        }
        scheduledUpdateTasks[launch.id] = task
    }
    
    private func scheduleUpdatesForAllLaunches(_ launches: [Launch]) {
        for launch in launches {
            scheduleUpdatesForLaunch(launch)
        }
    }
    
    private func checkForUpdates(forLaunch launch: Launch) async throws {
        let updatedLaunchURL = "\(baseURL)&id=\(launch.id)"
        let updatedLaunches = try await fetchFromSpaceDevs(urlString: updatedLaunchURL)
        
        if let updatedLaunch = updatedLaunches.first,
           hasLaunchChanged(old: launch, new: updatedLaunch) {
            await cache.cacheLaunches([updatedLaunch])
            NotificationCenter.default.post(
                name: .launchScheduleChanged,
                object: nil,
                userInfo: ["launchId": launch.id]
            )
        }
    }
    
    private func hasLaunchChanged(old: Launch, new: Launch) -> Bool {
        return old.net != new.net ||
               old.status != new.status ||
               old.location != new.location
    }
    
    private func cacheLaunches(_ launches: [Launch]) async {
        await cache.cacheLaunches(launches)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let launchScheduleChanged = Notification.Name("launchScheduleChanged")
}
