import SwiftUI

/// A list view displaying upcoming launches with searching, filtering, and detailed navigation.
struct LaunchListView: View {
    @StateObject var viewModel: LaunchViewModel
    let isNotableTab: Bool
    
    @State private var selectedLaunch: Launch?
    @State private var showingFilter = false
    
    private struct Metrics {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 20
    }
    
    /// When in notable mode, filter launches to only those marked as notable.
    private var displayedLaunches: [Launch] {
        if isNotableTab {
            return viewModel.filteredLaunches.filter { launch in
                launch.badges?.contains(.notable) ?? false
            }
        } else {
            return viewModel.filteredLaunches
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColors.spaceBlack
                    .ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: Metrics.cardSpacing) {
                        ForEach(displayedLaunches) { launch in
                            LaunchCard(launch: launch)
                                .onTapGesture { selectedLaunch = launch }
                                .padding(.horizontal, Metrics.horizontalPadding)
                                .accessibilityHint("Tap for details about \(launch.name)")
                        }
                    }
                    .padding(.vertical, Metrics.verticalPadding)
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(isNotableTab ? "Notable Launches" : "All Launches")
                .toolbar { toolbarContent }
                .searchable(text: $viewModel.searchQuery, prompt: "Search launches...")
                .overlay { overlayContent }
                .sheet(isPresented: $showingFilter) {
                    FilterView(criteria: $viewModel.criteria)
                        .presentationDetents([.medium, .large])
                }
                .sheet(item: $selectedLaunch) { launch in
                    LaunchDetailView(launch: launch)
                        .presentationDetents([.large])
                }
                .refreshable { await viewModel.fetchLaunches() }
                .task {
                    if viewModel.filteredLaunches.isEmpty {
                        await viewModel.fetchLaunches()
                    }
                }
            }
        }
        .accessibilityLabel(isNotableTab ? "List of notable launches." : "List of all launches.")
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // Filter Button
            Button {
                showingFilter = true
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    .labelStyle(IconOnlyLabelStyle())
                    .font(.title2)
                    .foregroundColor(ThemeColors.brightYellow)
            }
            .accessibilityLabel("Filter launches")
            .accessibilityHint("Tap to show filter options")
            
            // Refresh Button
            Button {
                Task { await viewModel.fetchLaunches() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .labelStyle(IconOnlyLabelStyle())
                    .font(.title2)
                    .foregroundColor(ThemeColors.brightYellow)
            }
            .accessibilityLabel("Refresh launches")
            .accessibilityHint("Tap to reload launch data")
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        switch viewModel.viewState {
        case .loading:
            loadingOverlay
        case .error(let message):
            ErrorView(error: message) {
                Task { await viewModel.fetchLaunches() }
            }
            .transition(.opacity)
            .accessibilityLabel("An error occurred while loading launches.")
            .accessibilityHint("Error details: \(message)")
        case .loaded, .idle:
            EmptyView()
        }
    }
    
    private var loadingOverlay: some View {
        ProgressView("Loading launches...")
            .scaleEffect(1.5)
            .tint(ThemeColors.brightYellow)
            .background(
                ThemeColors.spaceBlack
                    .opacity(0.7)
                    .ignoresSafeArea()
            )
    }
}
