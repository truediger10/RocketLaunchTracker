//
//  LaunchListView.swift
//  RocketLaunchTracker
//

import SwiftUI

/// A list view displaying upcoming launches without filtering/search.
struct LaunchListView: View {
    @StateObject var viewModel: LaunchViewModel
    
    // If you truly don’t want separate tabs for “Notable” vs. “All,” remove this:
    let isNotableTab: Bool
    
    @State private var selectedLaunch: Launch?

    private let horizontalPadding: CGFloat = 12
    private let verticalPadding: CGFloat = 10
    private let cardSpacing: CGFloat = 12

    var body: some View {
        NavigationView {
            ZStack {
                // Use a subtle gradient background instead of a solid color
                LinearGradient(gradient: Gradient(colors: [ThemeColors.darkGray, ThemeColors.spaceBlack]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: cardSpacing) {
                        ForEach(viewModel.launches) { launch in
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
                .navigationTitle(isNotableTab ? "Notable Launches" : "All Launches")
                .sheet(item: $selectedLaunch) { launch in
                    LaunchDetailView(launch: launch)
                }
                .refreshable {
                    await viewModel.fetchLaunches()
                }
                .task {
                    if viewModel.launches.isEmpty {
                        await viewModel.fetchLaunches()
                    }
                }
                .overlay { overlayContent }
            }
        }
    }

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
