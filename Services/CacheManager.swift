// Services/CacheManager.swift

import Foundation

/// Represents additional enriched data for a launch.
struct LaunchEnrichment: Codable {
    let shortDescription: String?
    let detailedDescription: String?
    let status: LaunchStatus? // Added 'status' property
}

class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let cacheDirectory: URL
    
    private var memoryEnrichments: [String: LaunchEnrichment] = [:]
    
    private init() {
        self.fileManager = .default
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.memoryEnrichments = [:]
        
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent("RocketLaunchTrackerCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        print("CacheManager initialized at directory: \(cacheDirectory.path)")
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
            let cache = try decoder.decode(LaunchEnrichment.self, from: data)
            // Add expiration logic if needed
            memoryEnrichments[id] = cache
            print("Loaded enrichment from disk cache for launch ID: \(id)")
            return cache
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
        let fileURL = cacheDirectory.appendingPathComponent("enrichment_\(id).cache")
        
        do {
            let data = try encoder.encode(enrichment)
            try data.write(to: fileURL, options: .atomicWrite)
            memoryEnrichments[id] = enrichment
            print("Successfully cached enrichment to disk and memory for launch ID: \(id)")
        } catch {
            print("Failed to cache enrichment for launch ID \(id) with error: \(error)")
            // Handle caching errors if necessary
        }
    }
}
