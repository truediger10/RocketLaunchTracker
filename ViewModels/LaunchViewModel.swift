//
//  LaunchViewModel.swift
//  RocketLaunchTracker
//

import Foundation
import SwiftUI

@MainActor
class LaunchViewModel: ObservableObject {
    enum ViewState {
        case idle, loading, loaded, error(String)
    }
    
    // MARK: - Published Properties
    @Published private(set) var launches: [Launch] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var viewState: ViewState = .idle
    @Published private(set) var hasMoreLaunches = true
    
    // MARK: - Private Properties
    private let apiManager: APIManager
    
    // MARK: - Initialization
    init(apiManager: APIManager = .shared) {
        self.apiManager = apiManager
        print("LaunchViewModel initialized")
    }
    
    // MARK: - Public Methods
    
    /// Fetch the initial set of launches or perform an incremental update.
    /// - Note: If launches already exist, new/updated launches are merged into the existing list.
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
            
            if launches.isEmpty {
                // Initial full load.
                print("Initial load: Fetched \(fetchedLaunches.count) launches")
                launches = fetchedLaunches
            } else {
                // Incremental update: merge new or updated launches.
                print("Incremental update: Fetched \(fetchedLaunches.count) launches")
                for updatedLaunch in fetchedLaunches {
                    if let index = launches.firstIndex(where: { $0.id == updatedLaunch.id }) {
                        launches[index] = updatedLaunch
                    } else {
                        // Insert new launches at the top.
                        launches.insert(updatedLaunch, at: 0)
                    }
                }
            }
            
            viewState = .loaded
            hasMoreLaunches = true
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
    
    /// Fetch the next page of launches (infinite scrolling).
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
                // Remove duplicates before appending.
                let newLaunches = moreLaunches.filter { newLaunch in
                    !launches.contains { $0.id == newLaunch.id }
                }
                launches.append(contentsOf: newLaunches)
                hasMoreLaunches = !newLaunches.isEmpty
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
}
