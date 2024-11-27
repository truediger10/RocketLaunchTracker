import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
class LaunchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var launches: [Launch] = []
    @Published var isLoading: Bool = false
    @Published var error: APIError?
    @Published var lastRefreshDate: Date?
    @Published var selectedStatus: LaunchStatus?
    @Published var selectedProvider: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let apiManager: APIManagerProtocol
    private let cacheManager: CacheProtocol
    private var currentOffset: Int = 0
    private let limit: Int = 10
    private var refreshTask: Task<Void, Never>?
    
    // MARK: - Public Properties
    var canLoadMore: Bool = true
    
    var filteredLaunches: [Launch] {
        launches.filter { launch in
            let statusMatch = selectedStatus.map { launch.status == $0 } ?? true
            let providerMatch = selectedProvider.map { launch.provider == $0 } ?? true
            return statusMatch && providerMatch
        }
    }
    
    // MARK: - Initialization
    init(apiManager: APIManagerProtocol = APIManager(),
         cacheManager: CacheProtocol = CacheManager.shared) {
        self.apiManager = apiManager
        self.cacheManager = cacheManager
        setupBackgroundCleanup()
        setupAutoRefresh()
    }
    
    // Removed deinit method
    
    // MARK: - Private Setup Methods
    private func setupBackgroundCleanup() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.cleanup()
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoRefresh() {
        // Auto refresh every 5 minutes if the app is active
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { [weak self] in
                    await self?.refreshLaunches()
                }
            }
            .store(in: &cancellables)
    }
    
    private func cleanup() {
        // This method is actor-isolated and safe to call from within the actor context
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    // MARK: - Public Methods
    func fetchLaunches(isRefreshing: Bool = false) async {
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        error = nil
        
        if isRefreshing {
            currentOffset = 0
            canLoadMore = true
        }
        
        do {
            let apiResponse = try await apiManager.fetchUpcomingLaunches(limit: limit, offset: currentOffset)
            var newLaunches: [Launch] = []
            
            for spaceDevsLaunch in apiResponse.results {
                let appLaunch = spaceDevsLaunch.toAppLaunch(withEnrichment: nil)
                do {
                    let enrichment = try await apiManager.enrichLaunchData(launch: appLaunch)
                    let enrichedLaunch = createEnrichedLaunch(from: appLaunch, with: enrichment)
                    newLaunches.append(enrichedLaunch)
                    try await cacheManager.cacheEnrichment(enrichment, for: enrichedLaunch.id)
                } catch {
                    newLaunches.append(appLaunch)
                }
            }
            
            await updateLaunches(with: newLaunches, isRefreshing: isRefreshing)
            try await cacheManager.cacheLaunches(self.launches)
            
            self.currentOffset += self.limit
            self.canLoadMore = apiResponse.results.count == self.limit
            self.lastRefreshDate = Date()
            
        } catch let apiError as APIError {
            await handleError(apiError)
        } catch {
            await handleError(.networkError(error))
        }
        
        isLoading = false
    }
    
    func loadMoreIfNeeded(currentItem: Launch) async {
        let thresholdIndex = launches.index(launches.endIndex, offsetBy: -5)
        if launches.firstIndex(where: { $0.id == currentItem.id }) == thresholdIndex {
            await fetchLaunches()
        }
    }
    
    func refreshLaunches() async {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.fetchLaunches(isRefreshing: true)
        }
    }
    
    func retryLastOperation() async {
        await fetchLaunches()
    }
    
    // MARK: - Filter Methods
    func applyFilters(status: LaunchStatus?, provider: String?) {
        selectedStatus = status
        selectedProvider = provider
    }
    
    func resetFilters() {
        selectedStatus = nil
        selectedProvider = nil
    }
    
    // MARK: - Private Helper Methods
    private func createEnrichedLaunch(from launch: Launch, with enrichment: LaunchEnrichment) -> Launch {
        Launch(
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
            wikiURL: launch.wikiURL,
            missionType: launch.missionType,
            orbit: launch.orbit,
            providerStats: launch.providerStats,
            padInfo: launch.padInfo,
            windowStart: launch.windowStart,
            windowEnd: launch.windowEnd,
            probability: launch.probability,
            weatherConcerns: launch.weatherConcerns,
            videoURLs: launch.videoURLs,
            infoURLs: launch.infoURLs,
            imageCredit: launch.imageCredit
        )
    }
    
    private func updateLaunches(with newLaunches: [Launch], isRefreshing: Bool) async {
        if isRefreshing {
            self.launches = newLaunches
        } else {
            self.launches.append(contentsOf: newLaunches)
        }
    }
    
    private func handleError(_ error: APIError) async {
        self.error = error
        do {
            let cachedLaunches = try await cacheManager.getCachedLaunches()
            self.launches = cachedLaunches
        } catch {
            self.error = .networkError(error)
        }
    }
}
