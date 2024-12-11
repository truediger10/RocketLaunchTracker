// App/RocketLaunchTrackerApp.swift

import SwiftUI

@main
struct RocketLaunchTrackerApp: App {
    @StateObject private var launchViewModel = LaunchViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                // All Launches Tab
                LaunchListView(viewModel: launchViewModel, isNotableTab: false)
                    .tabItem {
                        Label("All Launches", systemImage: "globe")
                    }
                
                // Notable Launches Tab
                LaunchListView(viewModel: launchViewModel, isNotableTab: true)
                    .tabItem {
                        Label("Notable Launches", systemImage: "star.fill")
                    }
            }
            .preferredColorScheme(.dark)
        }
    }
}
