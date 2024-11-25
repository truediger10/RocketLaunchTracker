import SwiftUI

struct LaunchListView: View {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var selectedLaunch: Launch?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.launches) { launch in
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
