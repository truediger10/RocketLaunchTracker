//
//  LaunchViewModel.swift
//  RocketLaunchTracker
//
//  SwiftUI ViewModel that calls LaunchService for data/pagination
//
import Foundation
import SwiftUI

@MainActor
class LaunchViewModel: ObservableObject {
    enum ViewState {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    @Published private(set) var launches: [Launch] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var viewState: ViewState = .idle
    @Published private(set) var hasMoreLaunches = true
    @Published var searchText: String = ""
    
    private let service: LaunchServiceProtocol
    
    init(service: LaunchServiceProtocol = LaunchService.shared) {
        self.service = service
        print("LaunchViewModel initialized")
    }
    
    /// Loads the first page of launches, or uses cached data if present & unexpired
    func fetchLaunches() async {
        guard !isLoading else { return }
        
        isLoading = true
        viewState = .loading
        errorMessage = nil
        
        do {
            let data = try await service.getLaunches()
            self.launches = data
            self.viewState = .loaded
            self.hasMoreLaunches = true  // We assume more pages might be available
        } catch {
            self.errorMessage = error.localizedDescription
            self.launches = []
            self.viewState = .error(errorMessage ?? "Unknown error")
            self.hasMoreLaunches = false
        }
        
        isLoading = false
    }
    
    /// Loads the next page of data (infinite scroll, load-more button, etc.)
    func fetchMoreLaunches() async {
        guard !isLoading && hasMoreLaunches else { return }
        
        isLoading = true
        viewState = .loading
        
        do {
            let newItems = try await service.getMoreLaunches()
            if newItems.isEmpty {
                // No further pages
                self.hasMoreLaunches = false
            } else {
                // Combine & remove duplicates
                let combined = (launches + newItems).uniqued { $0.id }
                self.launches = combined
            }
            self.viewState = .loaded
        } catch {
            self.errorMessage = error.localizedDescription
            self.viewState = .error(errorMessage ?? "Unknown error")
            self.hasMoreLaunches = false
        }
        
        isLoading = false
    }
}

extension LaunchViewModel {
    /// Returns launches filtered by the search text.
    var filteredLaunches: [Launch] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return launches }
        
        let query = trimmedQuery.lowercased()
        return launches.filter { launch in
            return launch.name.lowercased().contains(query) ||
                   launch.rocketName.lowercased().contains(query) ||
                   launch.provider.lowercased().contains(query) ||
                   launch.location.lowercased().contains(query)
        }
    }
}

extension LaunchViewModel {
    var suggestions: [String] {
        // If user hasn't typed anything, no suggestions
        guard !searchText.isEmpty else { return [] }
        
        // Example: gather rocketName & provider as suggestions
        // You can add name, shortDescription, etc. as well—whatever you want to suggest
        let rocketNames = launches.map(\.rocketName)
        let providers = launches.map(\.provider)
        
        // Combine them, remove duplicates
        let allSuggestions = Set(rocketNames + providers)
        
        // Filter to only those matching the current query
        let query = searchText.lowercased()
        let filtered = allSuggestions.filter { $0.lowercased().contains(query) }
        
        // Possibly limit how many you return
        return Array(filtered.prefix(8)) // e.g. first 8 matches
    }
}

extension Array {
    func uniqued<T: Hashable>(by keyPath: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert(keyPath($0)).inserted }
    }
}
