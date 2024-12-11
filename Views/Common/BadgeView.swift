// Views/Common/BadgeView.swift

import SwiftUI
import Foundation // Replace with your actual module name where Badge is defined

struct BadgeView: View {
    let badge: Badge
    
    // MARK: - Constants
    private enum Constants {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 4
        static let cornerRadius: CGFloat = 8
    }
    
    var body: some View {
        Text(badge.displayText)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .background(badgeBackgroundColor)
            .cornerRadius(Constants.cornerRadius)
            .accessibilityLabel("\(badge.displayText) badge")
    }
    
    /// Determines the background color based on badge type
    private var badgeBackgroundColor: Color {
        switch badge {
        case .live:
            return ThemeColors.red
        case .exclusive:
            return ThemeColors.purple
        case .firstLaunch:
            return ThemeColors.blue
        case .notable:
            return ThemeColors.orange
        }
    }
}

// Preview for SwiftUI Canvas
struct BadgeView_Previews: PreviewProvider {
    static var previews: some View {
        BadgeView(badge: .live)
            .padding()
    }
}
