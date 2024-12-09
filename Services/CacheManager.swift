import Foundation

/// Manages caching of launches and their enrichments.
actor CacheManager: @unchecked Sendable {
    // MARK: - Shared Instance
    static let shared = CacheManager()
    
    // MARK: - Constants
    private enum Constants {
        static let cacheFolder = "RocketLaunchCache"
        static let launchesFile = "launches.cache"
        static let launchCacheTime: TimeInterval = 5 * 60 // 5 minutes
        static let enrichmentCacheTime: TimeInterval = 24 * 60 * 60 // 24 hours
    }
    
    // MARK: - Properties
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var memoryLaunches: [Launch]?
    private var memoryEnrichments: [String: LaunchEnrichment]
    
    private init() {
        self.fileManager = .default
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.memoryEnrichments = [:]
        
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent(Constants.cacheFolder)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        print("CacheManager initialized at directory: \(cacheDirectory.path)")
    }
    
    // MARK: - Launch Caching
    /// Retrieves cached launches if available and not expired.
    /// - Returns: An optional array of `Launch` objects.
    func getCachedLaunches() async -> [Launch]? {
        print("Attempting to retrieve cached launches")
        if let launches = memoryLaunches {
            print("Retrieved launches from in-memory cache. Count: \(launches.count)")
            return launches
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(Constants.launchesFile)
        do {
            let data = try Data(contentsOf: fileURL)
            let cache = try decoder.decode(CachedLaunches.self, from: data)
            guard !cache.isExpired(expirationTime: Constants.launchCacheTime) else {
                print("Cached launches have expired")
                return nil
            }
            
            memoryLaunches = cache.launches
            print("Loaded launches from disk cache. Count: \(cache.launches.count)")
            return cache.launches
        } catch {
            print("Failed to load cached launches with error: \(error)")
            return nil
        }
    }
    
    /// Caches launches both in-memory and on disk.
    /// - Parameter launches: The launches to cache.
    func cacheLaunches(_ launches: [Launch]) async {
        print("Caching \(launches.count) launches")
        let cache = CachedLaunches(launches: launches, timestamp: Date())
        let fileURL = cacheDirectory.appendingPathComponent(Constants.launchesFile)
        
        do {
            let data = try encoder.encode(cache)
            try data.write(to: fileURL, options: .atomicWrite)
            memoryLaunches = launches
            print("Successfully cached launches to disk and memory")
        } catch {
            print("Failed to cache launches with error: \(error)")
            // Cache failure should not impact app functionality
        }
    }
    
    // MARK: - Enrichment Caching
    
    /// Retrieves cached enrichment for a specific launch ID if available and not expired.
    /// - Parameter id: The launch ID.
    /// - Returns: An optional `LaunchEnrichment` object.
    func getCachedEnrichment(for id: String) async -> LaunchEnrichment? {
        print("Attempting to retrieve cached enrichment for launch ID: \(id)")
        if let enrichment = memoryEnrichments[id] {
            print("Retrieved enrichment from in-memory cache for launch ID: \(id)")
            return enrichment
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("enrichment_\(id).cache")
        do {
            let data = try Data(contentsOf: fileURL)
            let cache = try decoder.decode(CachedEnrichment.self, from: data)
            guard !cache.isExpired(expirationTime: Constants.enrichmentCacheTime) else {
                print("Cached enrichment for launch ID \(id) has expired")
                return nil
            }
            
            memoryEnrichments[id] = cache.enrichment
            print("Loaded enrichment from disk cache for launch ID: \(id)")
            return cache.enrichment
        } catch {
            print("Failed to load cached enrichment for launch ID \(id) with error: \(error)")
            return nil
        }
    }
    
    /// Caches enrichment data for a specific launch ID both in-memory and on disk.
    /// - Parameters:
    ///   - enrichment: The enrichment data to cache.
    ///   - id: The launch ID.
    func cacheEnrichment(_ enrichment: LaunchEnrichment, for id: String) async {
        print("Caching enrichment for launch ID: \(id)")
        let cache = CachedEnrichment(enrichment: enrichment, timestamp: Date())
        let fileURL = cacheDirectory.appendingPathComponent("enrichment_\(id).cache")
        
        do {
            let data = try encoder.encode(cache)
            try data.write(to: fileURL, options: .atomicWrite)
            memoryEnrichments[id] = enrichment
            print("Successfully cached enrichment to disk and memory for launch ID: \(id)")
        } catch {
            print("Failed to cache enrichment for launch ID \(id) with error: \(error)")
            // Cache failure should not impact app functionality
        }
    }
}

// MARK: - Cache Models

/// Represents cached launches with a timestamp.
private struct CachedLaunches: Codable {
    let launches: [Launch]
    let timestamp: Date
    
    /// Determines if the cached data has expired based on the provided expiration time.
    /// - Parameter expirationTime: The time interval after which the cache is considered expired.
    /// - Returns: `true` if expired, `false` otherwise.
    func isExpired(expirationTime: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > expirationTime
    }
}

/// Represents cached enrichment data with a timestamp.
private struct CachedEnrichment: Codable {
    let enrichment: LaunchEnrichment
    let timestamp: Date
    
    /// Determines if the cached enrichment has expired based on the provided expiration time.
    /// - Parameter expirationTime: The time interval after which the cache is considered expired.
    /// - Returns: `true` if expired, `false` otherwise.
    func isExpired(expirationTime: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > expirationTime
    }
}
