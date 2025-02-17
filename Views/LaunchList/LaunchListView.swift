// File: LaunchListView.swift – Location: Views/LaunchList
import SwiftUI

struct LaunchListView: View {
    @StateObject var viewModel: LaunchViewModel
    let isNotableTab: Bool
    
    @State private var selectedLaunch: Launch?

    private let horizontalPadding: CGFloat = 12
    private let verticalPadding: CGFloat = 10
    private let cardSpacing: CGFloat = 12

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [ThemeColors.darkGray, ThemeColors.spaceBlack]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear
                            .frame(height: 0)
                            .id("top")
                        
                        LazyVStack(spacing: cardSpacing) {
                            let launchesToShow = isNotableTab
                                ? viewModel.filteredLaunches.filter { ($0.badges?.contains(.notable)) ?? false }
                                : viewModel.filteredLaunches
                            
                            ForEach(launchesToShow) { launch in
                                LaunchCard(launch: launch)
                                    .onTapGesture {
                                        selectedLaunch = launch
                                    }
                                    .onAppear {
                                        if launch.id == viewModel.launches.last?.id {
                                            Task {
                                                await viewModel.fetchMoreLaunches()
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, verticalPadding)
                    }
                    .onAppear {
                        // Scroll to top when switching tabs
                        withAnimation {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
                .navigationTitle(isNotableTab ? "Notable Launches" : "All Launches")
                .navigationBarTitleDisplayMode(.inline)  // <-- Add this line
                .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search Upcoming Launches")) {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        Button(action: { viewModel.searchText = suggestion }) {
                            Text(suggestion)
                        }
                    }
                }
                .sheet(item: $selectedLaunch) { launch in
                    // Present the detail view with interactive dismissal enabled
                    LaunchDetailView(launch: launch)
                        .interactiveDismissDisabled(false)
                }
                .refreshable {
                    await viewModel.fetchLaunches()
                }
                .task {
                    if viewModel.launches.isEmpty {
                        await viewModel.fetchLaunches()
                        await viewModel.fetchMoreLaunches()
                    }
                }
                .overlay(overlayContent)
            }
        }
    }

    // MARK: - Overlay Content
    @ViewBuilder
    private var overlayContent: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView("Loading...")
                .scaleEffect(1.3)
                .tint(ThemeColors.brightYellow)
                .background(Color.black.opacity(0.6).edgesIgnoringSafeArea(.all))
        case .error(let message):
            ErrorView(error: message) {
                Task { await viewModel.fetchLaunches() }
            }
            .transition(.opacity)
        default:
            EmptyView()
        }
    }
}
