import Foundation
import Combine
import SwiftUI

/// A view model that manages the state and business logic for the rocket launch list.
@MainActor
class LaunchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var launches: [Launch] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var searchQuery: String = ""
    @Published var criteria: LaunchCriteria = LaunchCriteria()
    
    // MARK: - Private Properties
    private let apiManager: APIManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
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
    
    // MARK: - Initialization
    init(apiManager: APIManager = .shared) {
        self.apiManager = apiManager
        setupEnrichmentObserver()
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
        let updatedBadges = existingLaunch.badges ?? []
        // If enrichment affects badges, adjust here. Otherwise, keep existing badges.
        // For now, we'll keep existing badges.
        
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
            badges: updatedBadges // Assign badges as existing or updated
        )
        print("Launch updated with enriched data for ID: \(launchId)")
    }
    
    // MARK: - Public Methods
    
    /// Fetches upcoming launches using the API manager.
    func fetchLaunches() async {
        guard !isLoading else {
            print("fetchLaunches() called but already loading")
            return
        }
        isLoading = true
        error = nil
        print("Starting fetchLaunches()")
        
        do {
            let fetched = try await apiManager.fetchLaunches()
            if fetched.isEmpty {
                print("No launches found")
                error = "No launches found"
            } else {
                print("Fetched \(fetched.count) launches")
                launches = fetched
            }
        } catch let fetchError {
            print("Error fetching launches: \(fetchError)")
            error = "Failed to load launches. Please try again. Details: \(fetchError.localizedDescription)"
            launches = []
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
        error = nil
        print("Starting fetchMoreLaunches()")
        
        do {
            if let more = try await apiManager.fetchMoreLaunches() {
                print("Fetched \(more.count) more launches")
                launches.append(contentsOf: more)
            } else {
                print("No additional launches to fetch")
            }
        } catch let fetchError {
            print("Error fetching more launches: \(fetchError)")
            error = "Failed to load more launches. Please try again. Details: \(fetchError.localizedDescription)"
        }
        
        isLoading = false
        print("Completed fetchMoreLaunches()")
    }
}
