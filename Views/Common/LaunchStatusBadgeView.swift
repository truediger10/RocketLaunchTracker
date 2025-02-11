import SwiftUI

/// Displays the launch status combined with any notable flag.
struct LaunchStatusBadgeView: View {
    let launch: Launch
    
    var body: some View {
        // Determine if the launch is notable based on its badges.
        let isNotable = launch.badges?.contains(.notable) ?? false
        
        // For now, all launches are upcoming. The badge displays accordingly.
        Text(isNotable ? "Notable Upcoming" : "Upcoming")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isNotable ? ThemeColors.lightGray : ThemeColors.lightGray)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
