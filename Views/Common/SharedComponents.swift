import SwiftUI

/// Displays launch status with color-coded indicators.
struct LaunchStatusTag: View {
    let status: LaunchStatus

    // MARK: - Constants
    private let circleSize: CGFloat = 10 // Increased from 8 to 10 for better visibility
    private let horizontalPadding: CGFloat = 12
    private let verticalPadding: CGFloat = 6
    private let cornerRadius: CGFloat = 12

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: circleSize, height: circleSize)
                .accessibilityHidden(true)

            Text(status.displayText)
                .font(.caption)
                .foregroundColor(ThemeColors.almostWhite)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(ThemeColors.darkGray.opacity(0.8))
        .cornerRadius(cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Launch Status: \(status.displayText)")
    }
}

/// Displays a badge with specific styling.
struct BadgeView: View {
    let badge: Badge

    // MARK: - Constants
    private let horizontalPadding: CGFloat = 8
    private let verticalPadding: CGFloat = 4
    private let cornerRadius: CGFloat = 8

    var body: some View {
        Text(badge.displayText)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(badge.color)
            .cornerRadius(cornerRadius)
            .accessibilityLabel("\(badge.displayText) badge")
    }
}

/// Generic detail item component for displaying labeled information.
struct DetailItem: View {
    // MARK: - Properties
    let label: String
    let value: String
    let icon: String?
    var iconColor: Color = ThemeColors.brightYellow

    // MARK: - Constants
    private let iconSize: CGFloat = 20 // Ensured consistent icon size
    private let spacing: CGFloat = 8
    private let lineSpacing: CGFloat = 2

    var body: some View {
        HStack(alignment: .center, spacing: spacing) { // Ensured vertical centering
            iconView
            contentView
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Subviews
    @ViewBuilder
    private var iconView: some View {
        if let icon {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.footnote)
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            Text(label)
                .font(.caption)
                .foregroundColor(ThemeColors.lightGray)

            Text(value)
                .font(.subheadline)
                .foregroundColor(ThemeColors.almostWhite)
                .lineSpacing(lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Animated shimmer effect for loading states.
struct ShimmerView: View {
    // MARK: - Properties
    let width: CGFloat
    let height: CGFloat
    var duration: Double = 1.0
    var angle: Double = 20

    @State private var move = false

    // MARK: - Constants
    private let gradient = Gradient(colors: [
        .white.opacity(0.6),
        .white.opacity(0.1),
        .white.opacity(0.6)
    ])

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: gradient,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width, height: height)
            .mask(Rectangle())
            .rotationEffect(.degrees(angle))
            .offset(x: move ? geometry.size.width : -geometry.size.width)
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    move.toggle()
                }
            }
        }
        .frame(width: width, height: height)
        .drawingGroup() // Enables Metal-backed rendering
        .accessibilityHidden(true)
    }
}

// MARK: - Preview Provider
struct SharedComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LaunchStatusTag(status: .successful)

            DetailItem(
                label: "Location",
                value: "Kennedy Space Center",
                icon: "location.fill"
            )

            ShimmerView(width: 200, height: 20)

            BadgeView(badge: .live)
            BadgeView(badge: .exclusive)
            BadgeView(badge: .firstLaunch)
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
