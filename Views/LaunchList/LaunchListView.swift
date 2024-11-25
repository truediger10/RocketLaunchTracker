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
            .navigationTitle("Launch Tracker")
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

struct LaunchCard: View {
    let launch: Launch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Section
            Group {
                if let imageURL = launch.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(ThemeColors.brightyellow)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            Image(systemName: "rocket")
                                .font(.system(size: 40))
                                .foregroundColor(ThemeColors.lunarRock)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "rocket")
                        .font(.system(size: 40))
                        .foregroundColor(ThemeColors.lunarRock)
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(ThemeColors.darkGray)
            .clipped()
            
            // Info Section
            VStack(alignment: .leading, spacing: 8) {
                Text(launch.name)
                    .font(.headline)
                    .foregroundColor(ThemeColors.almostWhite)
                
                Text(launch.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.lightGray)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(ThemeColors.brightyellow)
                    Text(launch.formattedDate)
                        .font(.caption)
                        .foregroundColor(ThemeColors.lightGray)
                }
            }
            .padding()
        }
        .background(ThemeColors.darkGray)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8)
    }
}
