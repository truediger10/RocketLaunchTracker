import SwiftUI

/// A list view displaying upcoming launches. Allows for searching, filtering, and viewing details.
/// Integrates with a view model (`LaunchViewModel`) for fetching and filtering data.
struct LaunchListView: View {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var selectedLaunch: Launch?
    @State private var showingFilter = false
    
    // Common spacing and padding constants
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 20
    private let cardSpacing: CGFloat = 20
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.spaceBlack
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: cardSpacing) {
                        // Display filtered launches
                        ForEach(viewModel.filteredLaunches) { launch in
                            LaunchCard(launch: launch)
                                .onTapGesture {
                                    // Present the detail view when a card is tapped
                                    selectedLaunch = launch
                                }
                                .padding(.horizontal, horizontalPadding)
                                .accessibilityHint("Tap for details about \(launch.name)")
                        }
                    }
                    .padding(.vertical, verticalPadding)
                }
                .navigationTitle("Upcoming Launches")
                .toolbar { toolbarContent }
                .searchable(
                    text: $viewModel.searchQuery,
                    prompt: "Search launches..."
                )
                .overlay { overlayContent }
                .sheet(isPresented: $showingFilter) {
                    FilterView(criteria: $viewModel.criteria)
                        .presentationDetents([.medium, .large])
                }
                .sheet(item: $selectedLaunch) { launch in
                    LaunchDetailView(launch: launch)
                        .presentationDetents([.large])
                }
                .refreshable {
                    // Pull-to-refresh to fetch new launches
                    await viewModel.fetchLaunches()
                }
                .task {
                    // Initial data load if needed
                    if viewModel.filteredLaunches.isEmpty {
                        await viewModel.fetchLaunches()
                    }
                }
            }
        }
        .accessibilityLabel("List of upcoming rocket launches.")
    }
    
    // MARK: - Toolbar Content
    /// A toolbar button to present filtering options.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingFilter = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(ThemeColors.brightyellow)
                    .font(.title2)
                    .accessibilityLabel("Filter launches")
            }
        }
    }
    
    // MARK: - Overlay Content
    /// Displays loading and error overlays when appropriate.
    @ViewBuilder
    private var overlayContent: some View {
        if viewModel.isLoading {
            loadingOverlay
        }
        
        if let error = viewModel.error {
            ErrorView(error: error) {
                Task { await viewModel.fetchLaunches() }
            }
            .transition(.opacity)
            // A concise accessibility label for the error state
            .accessibilityLabel("An error occurred while loading launches.")
            // Use the error string directly since it's not an Error type
            .accessibilityHint("Error details: \(error)")
        }
    }
    
    /// A loading state overlay indicating data is being fetched.
    private var loadingOverlay: some View {
        ProgressView()
            .scaleEffect(1.5)
            .tint(ThemeColors.brightyellow)
            .background(
                ThemeColors.spaceBlack
                    .opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
            )
            .accessibilityLabel("Loading upcoming launches...")
    }
}
