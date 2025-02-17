//
//  CacheManager.swift
//  RocketLaunchTracker
//
import Foundation

actor CacheManager: Sendable {
    static let shared = CacheManager()
    
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let cacheDirectory: URL
    
    private var memoryLaunches: [Launch] = []
    private var memoryEnrichments: [String: LaunchEnrichment] = [:]
    
    private init() {
        self.fileManager = .default
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent("RocketLaunchTrackerCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        print("CacheManager initialized at: \(cacheDirectory.path)")
    }
    
    // MARK: - Launch Caching
    
    func cacheLaunches(_ launches: [Launch]) async {
        let fileURL = cacheDirectory.appendingPathComponent("launches.cache")
        do {
            let data = try encoder.encode(launches)
            try data.write(to: fileURL, options: .atomicWrite)
            memoryLaunches = launches
            print("Successfully cached \(launches.count) launches")
        } catch {
            print("Failed to cache launches: \(error)")
        }
    }
    
    func getCachedLaunches() async -> [Launch]? {
        if !memoryLaunches.isEmpty {
            return memoryLaunches
        }
        let fileURL = cacheDirectory.appendingPathComponent("launches.cache")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try decoder.decode([Launch].self, from: data)
            memoryLaunches = decoded
            return decoded
        } catch {
            print("Failed to load cached launches: \(error)")
            return nil
        }
    }
    
    // MARK: - Enrichment Caching
    
    func getCachedEnrichment(for id: String) async -> LaunchEnrichment? {
        if let cached = memoryEnrichments[id] {
            return cached
        }
        let fileURL = cacheDirectory.appendingPathComponent("enrichment_\(id).cache")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let enrichment = try decoder.decode(LaunchEnrichment.self, from: data)
            memoryEnrichments[id] = enrichment
            return enrichment
        } catch {
            print("Failed to load enrichment for \(id): \(error)")
            return nil
        }
    }
    
    func cacheEnrichment(_ enrichment: LaunchEnrichment, for id: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("enrichment_\(id).cache")
        do {
            let data = try encoder.encode(enrichment)
            try data.write(to: fileURL, options: .atomicWrite)
            memoryEnrichments[id] = enrichment
            print("Cached enrichment for \(id)")
        } catch {
            print("Failed to cache enrichment for \(id): \(error)")
        }
    }
}
