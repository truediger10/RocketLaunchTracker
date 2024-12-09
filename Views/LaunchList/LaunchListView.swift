import SwiftUI

/// A list view displaying upcoming launches. Allows for searching, filtering, and viewing details.
struct LaunchListView: View {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var selectedLaunch: Launch?
    @State private var showingFilter = false
    @State private var showLaunchesWithBadgesOnly = false
    
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
                        ForEach(filteredLaunches) { launch in
                            LaunchCard(launch: launch)
                                .onTapGesture {
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
                    await viewModel.fetchLaunches()
                }
                .task {
                    if viewModel.filteredLaunches.isEmpty {
                        await viewModel.fetchLaunches()
                    }
                }
            }
        }
        .accessibilityLabel("List of upcoming rocket launches.")
    }
    
    /// Filters launches based on whether the user has enabled showing only launches with badges.
    private var filteredLaunches: [Launch] {
        showLaunchesWithBadgesOnly
            ? viewModel.filteredLaunches.filter { !($0.badges?.isEmpty ?? true) }
            : viewModel.filteredLaunches
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Toggle("Notable Launches", isOn: $showLaunchesWithBadgesOnly)
                .toggleStyle(SwitchToggleStyle(tint: ThemeColors.brightYellow))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingFilter = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(ThemeColors.brightYellow)
                    .font(.title2)
                    .accessibilityLabel("Filter launches")
            }
        }
    }
    
    // MARK: - Overlay Content
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
            .accessibilityLabel("An error occurred while loading launches.")
            .accessibilityHint("Error details: \(error)")
        }
    }
    
    /// Displays a loading overlay when fetching launches.
    private var loadingOverlay: some View {
        ProgressView("Loading launches...")
            .scaleEffect(1.5)
            .tint(ThemeColors.brightYellow)
            .background(
                ThemeColors.spaceBlack
                    .opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
            )
    }
}
