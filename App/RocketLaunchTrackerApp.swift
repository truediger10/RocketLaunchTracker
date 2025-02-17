//
//  RocketLaunchTrackerApp.swift
//  RocketLaunchTracker
//
import SwiftUI

@main
struct RocketLaunchTrackerApp: App {
    @StateObject private var launchViewModel = LaunchViewModel()
    
    // A custom init to set UITabBarAppearance for selected/unselected colors
    init() {
        configureTabBarColors()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                // "All Launches" Tab
                LaunchListView(viewModel: launchViewModel, isNotableTab: false)
                    .tabItem {
                        Label("All Launches", systemImage: "paperplane.fill")
                    }
                    .tag(0)
                
                // "Notable Launches" Tab
                LaunchListView(viewModel: launchViewModel, isNotableTab: true)
                    .tabItem {
                        Label("Notable Launches", systemImage: "star.fill")
                    }
                    .tag(1)
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Private Helpers
extension RocketLaunchTrackerApp {
    /// Configures the tab bar to show bright yellow for the selected tab
    /// and light gray for unselected tabs.
    private func configureTabBarColors() {
        let appearance = UITabBarAppearance()
        
        // Selected item appearance (bright yellow)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(ThemeColors.brightYellow)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(ThemeColors.brightYellow)
        ]
        
        // Unselected item appearance (light gray)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(ThemeColors.lightGray)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(ThemeColors.lightGray)
        ]
        
        // Assign to standardAppearance
        UITabBar.appearance().standardAppearance = appearance
        
        // Also set scrollEdgeAppearance on iOS 15+ (avoids reset on scroll)
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
