// ViewModels/LaunchViewModel.swift

import Foundation
import Combine
import SwiftUI

/// Represents the current state of the view.
enum ViewState {
    case idle
    case loading
    case loaded
    case error(String)
}

/// A view model that manages the state and business logic for the rocket launch list.
@MainActor
class LaunchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var launches: [Launch] = []
    @Published private(set) var isLoading = false
    @Published var error: String? // Made mutable by removing 'private(set)'
    @Published var searchQuery: String = ""
    @Published var criteria: LaunchCriteria = LaunchCriteria()
    @Published var viewState: ViewState = .idle // Tracks view state
    
    // MARK: - Private Properties
    private let apiManager: APIManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredLaunches: [Launch] {
        launches.filter { launch in
            let searchableFields = [
                launch.name,
                launch.rocketName, // Accessible via computed property
                launch.provider,
                launch.location
            ]
            
            let matchesQuery = searchQuery.isEmpty || searchableFields.contains {
                $0.localizedCaseInsensitiveContains(searchQuery)
            }
            
            return matchesQuery && criteria.matches(launch)
        }
    }
    
    // MARK: - Initialization
    init(apiManager: APIManager = .shared) {
        self.apiManager = apiManager
        setupEnrichmentObserver()
        setupBindings()
        print("LaunchViewModel initialized")
    }
    
    // MARK: - Private Methods
    
    /// Sets up an observer for launch enrichment updates.
    private func setupEnrichmentObserver() {
        print("Setting up enrichment observer")
        NotificationCenter.default.publisher(for: .launchEnrichmentUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let launchId = notification.userInfo?["launchId"] as? String else {
                    print("Received enrichment update notification with missing data")
                    return
                }
                
                print("Received enrichment update for launch ID: \(launchId)")
                Task {
                    await self.updateLaunchWithEnrichment(launchId)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sets up bindings for search query and criteria to update filtered launches.
    private func setupBindings() {
        Publishers.CombineLatest($searchQuery, $criteria)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] (query, criteria) in
                self?.applyFilters(query: query, criteria: criteria)
            }
            .store(in: &cancellables)
    }
    
    /// Updates a specific launch with its enriched data.
    /// - Parameter launchId: The ID of the launch to update.
    private func updateLaunchWithEnrichment(_ launchId: String) async {
        print("Updating launch with ID: \(launchId)")
        guard let index = launches.firstIndex(where: { $0.id == launchId }),
              let enrichment = await CacheManager.shared.getCachedEnrichment(for: launchId) else {
            print("No enrichment found for launch ID: \(launchId)")
            return
        }
        
        let existingLaunch = launches[index]
        let updatedLaunch = Launch(
            id: existingLaunch.id,
            name: existingLaunch.name,
            net: enrichment.status != nil ? Date() : existingLaunch.net, // Example update logic
            status: enrichment.status ?? existingLaunch.status,
            rocket: existingLaunch.rocket,
            provider: existingLaunch.provider,
            location: existingLaunch.location,
            imageURL: enrichment.shortDescription ?? existingLaunch.imageURL,
            shortDescription: enrichment.shortDescription ?? existingLaunch.shortDescription,
            detailedDescription: enrichment.detailedDescription ?? existingLaunch.detailedDescription,
            orbit: existingLaunch.orbit,
            wikiURL: existingLaunch.wikiURL,
            twitterURL: existingLaunch.twitterURL,
            badges: existingLaunch.badges // Assign badges as existing or updated if needed
        )
        launches[index] = updatedLaunch
        print("Launch updated with enriched data for ID: \(launchId)")
    }
    
    /// Applies filters based on search query and criteria.
    /// - Parameters:
    ///   - query: The search query.
    ///   - criteria: The filtering criteria.
    private func applyFilters(query: String, criteria: LaunchCriteria) {
        // Currently handled by the 'filteredLaunches' computed property
        // Additional logic can be added here if needed
        objectWillChange.send()
    }
    
    // MARK: - Public Methods
    
    /// Fetches upcoming launches using the API manager.
    func fetchLaunches() async {
        guard !isLoading else {
            print("fetchLaunches() called but already loading")
            return
        }
        isLoading = true
        viewState = .loading
        error = nil
        print("Starting fetchLaunches()")
        
        do {
            let fetched = try await apiManager.fetchLaunches()
            if fetched.isEmpty {
                print("No launches found")
                error = "No launches found"
                viewState = .error(error!)
            } else {
                print("Fetched \(fetched.count) launches")
                launches = fetched
                viewState = .loaded
            }
        } catch let fetchError as APIError {
            print("Error fetching launches: \(fetchError)")
            error = fetchError.localizedDescription
            launches = []
            viewState = .error(error!)
        } catch {
            print("Unexpected error fetching launches: \(error)")
            error = "An unexpected error occurred."
            launches = []
            viewState = .error(error!)
        }
        
        isLoading = false
        print("Completed fetchLaunches()")
    }
    
    /// Fetches more launches using the API manager.
    func fetchMoreLaunches() async {
        guard !isLoading else {
            print("fetchMoreLaunches() called but already loading")
            return
        }
        isLoading = true
        viewState = .loading
        error = nil
        print("Starting fetchMoreLaunches()")
        
        do {
            if let more = try await apiManager.fetchMoreLaunches() {
                print("Fetched \(more.count) more launches")
                launches.append(contentsOf: more)
                viewState = .loaded
            } else {
                print("No additional launches to fetch")
                viewState = .loaded
            }
        } catch let fetchError as APIError {
            print("Error fetching more launches: \(fetchError)")
            error = fetchError.localizedDescription
            viewState = .error(error!)
        } catch {
            print("Unexpected error fetching more launches: \(error)")
            error = "An unexpected error occurred."
            viewState = .error(error!)
        }
        
        isLoading = false
        print("Completed fetchMoreLaunches()")
    }
}
