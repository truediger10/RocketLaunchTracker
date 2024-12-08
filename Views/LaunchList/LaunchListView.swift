import SwiftUI

struct LaunchListView: View {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var selectedLaunch: Launch?
    @State private var showingFilter = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Use filteredLaunches instead of launches
                    ForEach(viewModel.filteredLaunches) { launch in
                        LaunchCard(launch: launch)
                            .onTapGesture {
                                selectedLaunch = launch
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(ThemeColors.spaceBlack)
            .navigationTitle("Upcoming Launches")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilter = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .accessibilityLabel("Filter")
                    }
                }
            }
            // Add search functionality
            .searchable(text: $viewModel.searchQuery, prompt: "Search launches...")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(ThemeColors.brightyellow)
                }
                
                if let error = viewModel.error {
                    ErrorView(error: error) {
                        Task {
                            await viewModel.fetchLaunches()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                // Show filter view modally
                FilterView(criteria: $viewModel.criteria)
            }
            .sheet(item: $selectedLaunch) { launch in
                LaunchDetailView(launch: launch)
            }
            .refreshable {
                await viewModel.fetchLaunches()
            }
            .task {
                await viewModel.fetchLaunches()
            }
        }
    }
}

struct ErrorView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(ThemeColors.brightyellow)
            Text(error)
                .foregroundColor(ThemeColors.almostWhite)
                .multilineTextAlignment(.center)
                .padding()
            Button("Retry", action: retry)
                .foregroundColor(ThemeColors.brightyellow)
        }
    }
}
