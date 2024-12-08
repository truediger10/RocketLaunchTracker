import Foundation

/// An actor that manages caching of launches and their enrichment data on disk and optionally in memory.
actor CacheManager {
    static let shared = CacheManager()
    
    private let launchCacheTime: TimeInterval = 5 * 60 // 5 minutes
    private let enrichmentCacheTime: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private var memoryLaunches: [Launch]?
    private var memoryEnrichments: [String: LaunchEnrichment] = [:]
    
    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("RocketLaunchCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Launches Caching
    
    func getCachedLaunches() async -> [Launch]? {
        if let launches = memoryLaunches {
            print("📦 Retrieved launches from in-memory cache")
            return launches
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("launches.cache")
        guard let data = try? Data(contentsOf: fileURL),
              let cache = try? JSONDecoder().decode(CachedLaunches.self, from: data),
              !cache.isExpired(expirationTime: launchCacheTime) else {
            return nil
        }
        
        memoryLaunches = cache.launches
        return cache.launches
    }
    
    func cacheLaunches(_ launches: [Launch]) async {
        let cache = CachedLaunches(launches: launches, timestamp: Date())
        let fileURL = cacheDirectory.appendingPathComponent("launches.cache")
        
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: fileURL)
            memoryLaunches = launches
            print("✅ Successfully cached \(launches.count) launches.")
        } catch {
            print("Failed to cache launches: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Enrichment Caching
    
    func getCachedEnrichment(for id: String) async -> LaunchEnrichment? {
        if let enrichment = memoryEnrichments[id] {
            print("📦 Retrieved enrichment for \(id) from in-memory cache")
            return enrichment
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("enrichment_\(id).cache")
        guard let data = try? Data(contentsOf: fileURL),
              let cache = try? JSONDecoder().decode(CachedEnrichment.self, from: data),
              !cache.isExpired(expirationTime: enrichmentCacheTime) else {
            return nil
        }
        
        memoryEnrichments[id] = cache.enrichment
        return cache.enrichment
    }
    
    func cacheEnrichment(_ enrichment: LaunchEnrichment, for id: String) async {
        let cache = CachedEnrichment(enrichment: enrichment, timestamp: Date())
        let fileURL = cacheDirectory.appendingPathComponent("enrichment_\(id).cache")
        
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: fileURL)
            memoryEnrichments[id] = enrichment
            print("✅ Successfully cached enrichment for launch \(id).")
        } catch {
            print("Failed to cache enrichment: \(error.localizedDescription)")
        }
    }
}

// MARK: - Cache Models
private struct CachedLaunches: Codable {
    let launches: [Launch]
    let timestamp: Date
    
    func isExpired(expirationTime: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > expirationTime
    }
}

private struct CachedEnrichment: Codable {
    let enrichment: LaunchEnrichment
    let timestamp: Date
    
    func isExpired(expirationTime: TimeInterval) -> Bool {
        Date().timeIntervalSince(timestamp) > expirationTime
    }
}
