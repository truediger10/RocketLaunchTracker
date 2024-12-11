import SwiftUI

/// A list view displaying upcoming launches. Allows for searching, filtering, and viewing details.
struct LaunchListView: View {
    @ObservedObject var viewModel: LaunchViewModel
    let isNotableTab: Bool
    
    @State private var selectedLaunch: Launch?
    @State private var showingFilter = false
    
    // Common spacing and padding constants
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 20
    private let cardSpacing: CGFloat = 20
    
    private var displayedLaunches: [Launch] {
        isNotableTab
        ? viewModel.filteredLaunches.filter { !($0.badges?.isEmpty ?? true) }
        : viewModel.filteredLaunches
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.spaceBlack
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: cardSpacing) {
                        ForEach(displayedLaunches) { launch in
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
                .navigationTitle(isNotableTab ? "Notable Launches" : "All Launches")
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
        .accessibilityLabel(isNotableTab ? "List of notable launches." : "List of all launches.")
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
        switch viewModel.viewState {
        case .loading:
            loadingOverlay
        case .error(let message):
            ErrorView(error: message) {
                Task {
                    await viewModel.fetchLaunches()
                }
            }
            .transition(.opacity)
            .accessibilityLabel("An error occurred while loading launches.")
            .accessibilityHint("Error details: \(message)")
        case .loaded, .idle:
            EmptyView()
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
