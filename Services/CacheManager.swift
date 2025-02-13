//
//  CacheManager.swift
//  RocketLaunchTracker
//

import Foundation

/// Manages caching of launch enrichments to optimize performance and reduce redundant API calls.
/// Converted to an `actor` for safe concurrent access of mutable properties.
actor CacheManager: Sendable {
    static let shared = CacheManager()
    
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let cacheDirectory: URL
    
    private var memoryEnrichments: [String: LaunchEnrichment] = [:]
    private var memoryLaunches: [Launch] = []
    
    private init() {
        self.fileManager = .default
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent("RocketLaunchTrackerCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        print("CacheManager initialized at directory: \(cacheDirectory.path)")
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
            print("Failed to cache launches with error: \(error)")
        }
    }
    
    func getCachedLaunches() async -> [Launch]? {
        if !memoryLaunches.isEmpty {
            return memoryLaunches
        }
        let fileURL = cacheDirectory.appendingPathComponent("launches.cache")
        do {
            let data = try Data(contentsOf: fileURL)
            let launches = try decoder.decode([Launch].self, from: data)
            memoryLaunches = launches
            return launches
        } catch {
            print("Failed to load cached launches with error: \(error)")
            return nil
        }
    }
    
    // MARK: - Enrichment Caching
    
    func getCachedEnrichment(for id: String) async -> LaunchEnrichment? {
        print("Attempting to retrieve cached enrichment for launch ID: \(id)")
        if let enrichment = memoryEnrichments[id] {
            print("Retrieved enrichment from in-memory cache for launch ID: \(id)")
            return enrichment
        }
        let fileURL = cacheDirectory.appendingPathComponent("enrichment_\(id).cache")
        do {
            let data = try Data(contentsOf: fileURL)
            let cached = try decoder.decode(LaunchEnrichment.self, from: data)
            memoryEnrichments[id] = cached
            print("Loaded enrichment from disk cache for launch ID: \(id)")
            return cached
        } catch {
            print("Failed to load cached enrichment for launch ID \(id) with error: \(error)")
            return nil
        }
    }
    
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
        }
    }
    
    func updateLaunch(_ launch: Launch) async {
        if let index = memoryLaunches.firstIndex(where: { $0.id == launch.id }) {
            memoryLaunches[index] = launch
        }
        await cacheLaunches(memoryLaunches)
    }
}
