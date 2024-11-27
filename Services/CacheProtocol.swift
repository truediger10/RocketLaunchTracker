import Foundation

/// A protocol defining the caching operations for Launch data and their enrichment.
protocol CacheProtocol {
    func cacheLaunches(_ launches: [Launch]) async throws
    func getCachedLaunches() async throws -> [Launch]
    func cacheEnrichment(_ enrichment: LaunchEnrichment, for launchID: String) async throws
    func getCachedEnrichment(for launchID: String) async throws -> LaunchEnrichment
    func clearCache() async throws
}

/// Protocol extension providing default implementation of optional requirements
extension CacheProtocol {
    func clearCache() async throws {
        // Default empty implementation
    }
}
