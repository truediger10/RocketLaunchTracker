import Foundation

actor CacheManager {
    static let shared = CacheManager()
    
    private struct CacheEntry<T: Codable>: Codable {
        let value: T
        let timestamp: Date
    }
    
    private var launchCache: [String: CacheEntry<Launch>] = [:]
    private var enrichmentCache: [String: CacheEntry<LaunchEnrichment>] = [:]
    
    private init() {
        Task {
            await loadInitialCache()
        }
    }
    
    private func loadInitialCache() async {
        do {
            try await loadCaches()
        } catch {
            print("Failed to load initial cache: \(error)")
        }
    }
    
    func cacheLaunches(_ launches: [Launch]) async {
        for launch in launches {
            let entry = CacheEntry(value: launch, timestamp: Date())
            launchCache[launch.id] = entry
        }
        try? await saveCaches()
    }
    
    func getCachedLaunches() async -> [Launch]? {
        let now = Date()
        let validEntries = launchCache.filter {
            now.timeIntervalSince($0.value.timestamp) < Config.shared.cacheExpirationInterval
        }
        return validEntries.isEmpty ? nil : validEntries.values.map { $0.value }
    }
    
    func cacheEnrichment(_ enrichment: LaunchEnrichment, for launchId: String) async {
        let entry = CacheEntry(value: enrichment, timestamp: Date())
        enrichmentCache[launchId] = entry
        try? await saveCaches()
    }
    
    func getCachedEnrichment(for launchId: String) async -> LaunchEnrichment? {
        guard let entry = enrichmentCache[launchId],
              Date().timeIntervalSince(entry.timestamp) < Config.shared.cacheExpirationInterval else {
            return nil
        }
        return entry.value
    }
    
    private func saveCaches() async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let launchData = try encoder.encode(launchCache)
        let enrichmentData = try encoder.encode(enrichmentCache)
        
        try launchData.write(to: Self.launchCacheURL)
        try enrichmentData.write(to: Self.enrichmentCacheURL)
    }
    
    private func loadCaches() async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let launchData = try? Data(contentsOf: Self.launchCacheURL) {
            launchCache = try decoder.decode([String: CacheEntry<Launch>].self, from: launchData)
        }
        
        if let enrichmentData = try? Data(contentsOf: Self.enrichmentCacheURL) {
            enrichmentCache = try decoder.decode([String: CacheEntry<LaunchEnrichment>].self, from: enrichmentData)
        }
    }
    
    private static var launchCacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("launchCache.json")
    }
    
    private static var enrichmentCacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("enrichmentCache.json")
    }
}
