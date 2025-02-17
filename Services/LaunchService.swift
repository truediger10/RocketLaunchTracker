//
//  LaunchService.swift
//  RocketLaunchTracker
//
//  1) fetch data from Space Devs via APIManager
//  2) Enrich each launch with OpenAI if not already cached
//  3) Store final results in CacheManager
//  4) getMoreLaunches() for multiple pages
//
import Foundation

protocol LaunchServiceProtocol: AnyObject {
    func getLaunches() async throws -> [Launch]
    func getMoreLaunches() async throws -> [Launch]
}

final class LaunchService: LaunchServiceProtocol {
    static let shared = LaunchService()
    
    private let apiManager: APIManager
    private let cache: CacheManager
    private let openAIService: OpenAIService
    
    private init(apiManager: APIManager = .shared,
                 cache: CacheManager = .shared,
                 openAIService: OpenAIService = .shared) {
        self.apiManager = apiManager
        self.cache = cache
        self.openAIService = openAIService
    }
    
    // MARK: - Public
    
    /// Fetch the first page or return the cached data if still valid
    func getLaunches() async throws -> [Launch] {
        // Check cache first
        if let cached = await cache.getCachedLaunches(),
           !cached.isEmpty,
           !isCacheExpired() {
            return cached
        }
        
        let newLaunches = try await apiManager.fetchLaunches()
        let enriched = try await enrichLaunches(newLaunches)
        
        // Save final results
        await cache.cacheLaunches(enriched)
        UserDefaults.standard.set(Date(), forKey: "lastFetchDate")
        
        return enriched
    }
    
    /// Fetch the next page, if any, merge with cache, return newly fetched
    func getMoreLaunches() async throws -> [Launch] {
        guard let nextPage = try await apiManager.fetchMoreLaunches(), !nextPage.isEmpty else {
            // If nil or empty, no more pages
            return []
        }
        
        let enrichedNew = try await enrichLaunches(nextPage)
        // Merge with existing
        let existing = await cache.getCachedLaunches() ?? []
        let combined = (existing + enrichedNew).uniqued { $0.id }
        
        await cache.cacheLaunches(combined)
        return enrichedNew
    }
    
    // MARK: - Private
    
    private func enrichLaunches(_ launches: [Launch]) async throws -> [Launch] {
        var results: [Launch] = []
        for launch in launches {
            if let existing = await cache.getCachedEnrichment(for: launch.id) {
                results.append(mergeEnrichment(launch, existing))
            } else {
                let newEnrichment = try await openAIService.enrichLaunch(launch)
                await cache.cacheEnrichment(newEnrichment, for: launch.id)
                results.append(mergeEnrichment(launch, newEnrichment))
            }
        }
        return results
    }
    
    private func mergeEnrichment(_ launch: Launch,
                                 _ enrichment: LaunchEnrichment) -> Launch {
        var updated = launch
        updated.shortDescription = enrichment.shortDescription
        updated.detailedDescription = enrichment.detailedDescription
        return updated
    }
    
    private func isCacheExpired(maxAge: TimeInterval = 3600) -> Bool {
        guard let lastFetch = UserDefaults.standard.object(forKey: "lastFetchDate") as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastFetch) > maxAge
    }
}


