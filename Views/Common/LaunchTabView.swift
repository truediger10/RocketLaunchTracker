import SwiftUI
import UIKit

/// An enumeration representing the two launch tabs.
enum LaunchTab: Equatable {
    case notable
    case upcoming

    var title: String {
        switch self {
        case .notable: return "Notable"
        case .upcoming: return "Upcoming"
        }
    }

    var systemImageName: String {
        switch self {
        case .notable: return "medal.star.fill"
        case .upcoming: return "circle.hexagongrid"
        }
    }
}

/// A view that displays the main tabbed interface for launch lists.
struct LaunchTabView: View {
    @StateObject private var viewModel = LaunchViewModel()
    @State private var selectedTab: LaunchTab = .notable

    var body: some View {
        TabView(selection: $selectedTab) {
            // Display notable launches.
            LaunchListView(viewModel: viewModel, isNotableTab: true)
                .tabItem {
                    TabButton(tab: .notable, isSelected: selectedTab == .notable)
                }
                .tag(LaunchTab.notable)

            // Display upcoming (or all) launches.
            LaunchListView(viewModel: viewModel, isNotableTab: false)
                .tabItem {
                    TabButton(tab: .upcoming, isSelected: selectedTab == .upcoming)
                }
                .tag(LaunchTab.upcoming)
        }
        .tint(ThemeColors.brightYellow)
    }
}

/// A custom tab button used in the LaunchTabView.
struct TabButton: View {
    let tab: LaunchTab
    let isSelected: Bool

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.systemImageName)
                .font(.title2)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.3), value: isAnimating)

            Text(tab.title)
                .font(.footnote)
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .padding(.horizontal, 16)
        .onTapGesture {
            isAnimating.toggle()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

