import SwiftUI

struct LaunchListView: View {
    @StateObject private var viewModel = LaunchViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.launches.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        await viewModel.retryLastOperation()
                    }
                } else if viewModel.launches.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(viewModel.filteredLaunches) { launch in
                            NavigationLink(destination: LaunchDetailView(launch: launch)) {
                                LaunchCard(launch: launch)
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreIfNeeded(currentItem: launch)
                                        }
                                    }
                            }
                        }

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Rocket Launches")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LaunchFilterView(selectedStatus: $viewModel.selectedStatus, selectedProvider: $viewModel.selectedProvider)) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchLaunches()
                }
            }
        }
    }
}
