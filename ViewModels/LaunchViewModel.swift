import Foundation
import SwiftUI

@MainActor
class LaunchViewModel: ObservableObject {
    @Published private(set) var launches: [Launch] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    // New properties for search & filtering
    @Published var searchQuery: String = ""
    @Published var criteria: LaunchCriteria = LaunchCriteria()
    
    private let apiManager: APIManager
    
    init(apiManager: APIManager = .shared) {
        self.apiManager = apiManager
    }
    
    /// Computed property that returns filtered results based on searchQuery and criteria
    var filteredLaunches: [Launch] {
        launches.filter { launch in
            // Search filter
            let matchesQuery = searchQuery.isEmpty ||
                launch.name.localizedCaseInsensitiveContains(searchQuery) ||
                launch.rocketName.localizedCaseInsensitiveContains(searchQuery) ||
                launch.provider.localizedCaseInsensitiveContains(searchQuery) ||
                (launch.location.localizedCaseInsensitiveContains(searchQuery))
            
            // Criteria filter
            let matchesCriteria = criteria.matches(launch)
            
            return matchesQuery && matchesCriteria
        }
    }
    
    /// Fetches the initial list of launches.
    func fetchLaunches() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            print("🚀 Fetching launches...")
            let fetched = try await apiManager.fetchLaunches()
            if fetched.isEmpty {
                error = "No launches found"
            }
            self.launches = fetched
            print("📱 Received \(launches.count) launches")
        } catch {
            print("❌ Error fetching launches: \(error.localizedDescription)")
            self.error = "Failed to load launches. Please try again."
            launches = []
        }
        
        isLoading = false
    }
    
    /// Fetches the next page of launches if available (pagination).
    func fetchMoreLaunches() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            print("🚀 Fetching more launches...")
            if let more = try await apiManager.fetchMoreLaunches() {
                if more.isEmpty {
                    print("ℹ️ No additional launches returned.")
                } else {
                    self.launches.append(contentsOf: more)
                    print("📱 Added \(more.count) more launches, total now \(launches.count)")
                }
            } else {
                print("ℹ️ No more pages to load.")
            }
        } catch {
            print("❌ Error fetching more launches: \(error.localizedDescription)")
            self.error = "Failed to load more launches. Please try again."
        }
        
        isLoading = false
    }
}
