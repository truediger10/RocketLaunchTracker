// LaunchViewModel.swift

import Foundation
import Combine
import SwiftUI

@MainActor
class LaunchViewModel: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case error(String)
        case loaded
    }
    
    @Published private(set) var launches: [Launch] = []
    @Published private(set) var viewState: ViewState = .idle
    @Published var searchQuery: String = ""
    @Published var criteria: LaunchCriteria = LaunchCriteria()
    @Published var isLoading: Bool = false
    
    private let apiManager: APIManager
    private let cache: CacheManager
    private var cancellables = Set<AnyCancellable>()
    private var loadingTask: Task<Void, Never>?
    
    init(apiManager: APIManager = .shared, cache: CacheManager = .shared) {
        self.apiManager = apiManager
        self.cache = cache
        setupEnrichmentObserver()
        setupInitialLoad()
    }
    
    private func setupInitialLoad() {
        loadingTask = Task { await fetchLaunches() }
    }
    
    var filteredLaunches: [Launch] {
        launches.filter { launch in
            let searchableFields = [
                launch.name,
                launch.rocketName,
                launch.provider,
                launch.location
            ]
            
            let matchesQuery = searchQuery.isEmpty || searchableFields.contains {
                $0.localizedCaseInsensitiveContains(searchQuery)
            }
            
            return matchesQuery && criteria.matches(launch)
        }
    }
    
    var notableLaunches: [Launch] {
        filteredLaunches.filter { launch in
            guard let badges = launch.badges else { return false }
            return !badges.isEmpty
        }
    }
    
    var regularLaunches: [Launch] {
        filteredLaunches
    }
    
    func fetchLaunches() async {
        guard viewState != .loading else { return }
        viewState = .loading
        
        do {
            let fetched = try await apiManager.fetchLaunches()
            if fetched.isEmpty {
                viewState = .error("No launches available")
            } else {
                launches = fetched
                viewState = .loaded
            }
        } catch let error as APIError {
            viewState = .error(error.localizedDescription)
            if let cached = await cache.getCachedLaunches() {
                launches = cached
            }
        } catch {
            viewState = .error("An unexpected error occurred")
        }
    }
    
    func fetchMoreLaunches() async {
        guard viewState != .loading else { return }
        viewState = .loading
        
        do {
            let moreLaunches = try await apiManager.fetchMoreLaunches()
            if !moreLaunches.isEmpty {
                launches.append(contentsOf: moreLaunches)
            }
            viewState = .loaded
        } catch {
            viewState = .error("Failed to load more launches")
        }
    }
    
    func retry() {
        Task { await fetchLaunches() }
    }
    
    private func setupEnrichmentObserver() {
        NotificationCenter.default.publisher(for: .launchEnrichmentUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let launchId = notification.userInfo?["launchId"] as? String else { return }
                Task { await self.updateLaunchWithEnrichment(launchId) }
            }
            .store(in: &cancellables)
    }
    
    private func updateLaunchWithEnrichment(_ launchId: String) async {
        guard let index = launches.firstIndex(where: { $0.id == launchId }),
              let enrichment = await cache.getCachedEnrichment(for: launchId) else { return }
        
        let existingLaunch = launches[index]
        launches[index] = Launch(
            id: existingLaunch.id,
            name: existingLaunch.name,
            launchDate: existingLaunch.launchDate,
            status: existingLaunch.status,
            rocketName: existingLaunch.rocketName,
            provider: existingLaunch.provider,
            location: existingLaunch.location,
            imageURL: existingLaunch.imageURL,
            shortDescription: enrichment.shortDescription,
            detailedDescription: enrichment.detailedDescription,
            orbit: existingLaunch.orbit,
            wikiURL: existingLaunch.wikiURL,
            twitterURL: existingLaunch.twitterURL,
            badges: existingLaunch.badges
        )
    }
    
    deinit {
        loadingTask?.cancel()
        cancellables.removeAll()
    }
}
