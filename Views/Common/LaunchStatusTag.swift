import SwiftUI

struct LaunchStatusTag: View {
    let status: LaunchStatus
    
    var body: some View {
        HStack(spacing: Constants.spacing) {
            Circle()
                .fill(statusColor)
                .frame(width: Constants.circleSize, height: Constants.circleSize)
                .accessibilityHidden(true)
            
            Text(status.displayText)
                .font(.caption)
                .foregroundColor(ThemeColors.almostWhite)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background(ThemeColors.darkGray.opacity(0.8))
        .cornerRadius(Constants.cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Launch Status: \(status.displayText)")
    }
    
    /// Determines the color based on launch status
    private var statusColor: Color {
        switch status {
        case .upcoming:
            return ThemeColors.brightYellow
        case .launching:
            return .blue
        case .successful:
            return .green
        case .failed:
            return .red
        case .delayed:
            return .orange
        case .cancelled:
            return .gray
        case .unknown:
            return ThemeColors.lunarRock
        }
    }
    
    // MARK: - Constants
    private enum Constants {
        static let circleSize: CGFloat = 10
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 6
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 8
    }
}
