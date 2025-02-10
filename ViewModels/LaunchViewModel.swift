// ViewModels/LaunchViewModel.swift

import Foundation
import Combine
import SwiftUI

@MainActor
class LaunchViewModel: ObservableObject {
    enum ViewState {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    // MARK: - Published Properties
    @Published private(set) var launches: [Launch] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var criteria: LaunchCriteria = LaunchCriteria()
    @Published var viewState: ViewState = .idle
    @Published private(set) var hasMoreLaunches = true
    
    // MARK: - Private Properties
    private let apiManager: APIManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredLaunches: [Launch] {
        launches.filter { launch in
            let searchableFields: [String] = [
                launch.name,
                launch.rocket,
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
    
    // MARK: - Public Methods
    func fetchLaunches() async {
        guard !isLoading else {
            print("fetchLaunches() called but already loading")
            return
        }
        isLoading = true
        viewState = .loading
        errorMessage = nil
        print("Starting fetchLaunches()")
        
        do {
            let fetchedLaunches = try await apiManager.fetchLaunches()
            if fetchedLaunches.isEmpty {
                print("No launches found")
                errorMessage = "No launches found"
                viewState = .error(errorMessage ?? "Unknown error")
                hasMoreLaunches = false
            } else {
                print("Fetched \(fetchedLaunches.count) launches")
                launches = fetchedLaunches
                viewState = .loaded
                hasMoreLaunches = true
            }
        } catch {
            print("Unexpected error fetching launches: \(error)")
            errorMessage = error.localizedDescription
            launches = []
            viewState = .error(errorMessage ?? "Unknown error")
            hasMoreLaunches = false
        }
        
        isLoading = false
        print("Completed fetchLaunches()")
    }
    
    func fetchMoreLaunches() async {
        guard !isLoading && hasMoreLaunches else {
            print("fetchMoreLaunches() called but already loading or no more launches")
            return
        }
        
        isLoading = true
        viewState = .loading
        print("Starting fetchMoreLaunches()")
        
        do {
            if let moreLaunches = try await apiManager.fetchMoreLaunches() {
                print("Fetched \(moreLaunches.count) more launches")
                // Remove duplicates before appending
                let newLaunches = moreLaunches.filter { newLaunch in
                    !launches.contains { $0.id == newLaunch.id }
                }
                launches.append(contentsOf: newLaunches)
                hasMoreLaunches = !moreLaunches.isEmpty
            } else {
                print("No additional launches to fetch")
                hasMoreLaunches = false
            }
            viewState = .loaded
        } catch {
            print("Unexpected error fetching more launches: \(error)")
            errorMessage = error.localizedDescription
            viewState = .error(errorMessage ?? "Unknown error")
            hasMoreLaunches = false
        }
        
        isLoading = false
        print("Completed fetchMoreLaunches()")
    }
    
    // MARK: - Private Methods
    private func setupEnrichmentObserver() {
        print("Setting up enrichment observer")
        NotificationCenter.default.publisher(for: .launchEnrichmentUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
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
    
    private func setupBindings() {
        Publishers.CombineLatest($searchQuery, $criteria)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] (query, criteria) in
                self?.applyFilters(query: query, criteria: criteria)
            }
            .store(in: &cancellables)
    }
    
    private func updateLaunchWithEnrichment(_ launchId: String) async {
        print("Updating launch with ID: \(launchId)")
        guard let index = launches.firstIndex(where: { $0.id == launchId }) else {
            print("No launch found with ID: \(launchId)")
            return
        }
        
        do {
            let fetchedLaunches = try await apiManager.fetchLaunches()
            if let updatedLaunch = fetchedLaunches.first(where: { $0.id == launchId }) {
                launches[index] = updatedLaunch
                print("Launch updated with enriched data for ID: \(launchId)")
            } else {
                print("Launch with ID: \(launchId) not found after enrichment.")
            }
        } catch {
            print("Failed to update launch with ID: \(launchId) due to error: \(error)")
            errorMessage = error.localizedDescription
            viewState = .error(errorMessage ?? "Unknown error")
        }
    }
    
    private func applyFilters(query: String, criteria: LaunchCriteria) {
        objectWillChange.send()
    }
}
