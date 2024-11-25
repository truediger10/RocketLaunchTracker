import SwiftUI

struct LaunchListView: View {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var selectedLaunch: Launch?
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.spaceBlack.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(ThemeColors.brightyellow)
                } else if !viewModel.launches.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.launches) { launch in
                                LaunchCard(launch: launch)
                                    .onTapGesture {
                                        selectedLaunch = launch
                                    }
                            }
                        }
                        .padding()
                    }
                } else if let error = viewModel.error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(ThemeColors.brightyellow)
                        Text(error)
                            .foregroundColor(ThemeColors.almostWhite)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            Task {
                                await viewModel.fetchLaunches()
                            }
                        }
                        .foregroundColor(ThemeColors.brightyellow)
                    }
                    .padding()
                } else {
                    Text("No launches available")
                        .foregroundColor(ThemeColors.almostWhite)
                }
            }
            .navigationTitle("Upcoming Launches")
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

