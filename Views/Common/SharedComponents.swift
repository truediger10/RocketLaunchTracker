import SwiftUI

/// A badge-like view showing the launch status with a colored dot and label.
struct LaunchStatusTag: View {
    let status: LaunchStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(status.displayText)
                .font(.caption)
                .foregroundColor(ThemeColors.almostWhite)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("Launch Status: \(status.displayText)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(ThemeColors.darkGray.opacity(0.8))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .successful: return ThemeColors.brightyellow
        case .upcoming: return .blue
        case .launching: return .green
        case .failed: return .red
        case .delayed: return .orange
        case .cancelled: return .gray
        }
    }
}

/// Displays a title, an icon, and a text block, suitable for showing descriptive info.
struct DetailItem: View {
    let title: String
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(ThemeColors.brightyellow)
                .font(.footnote) // unified icon size
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(ThemeColors.lightGray)
                    .accessibilityLabel("\(title):")
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.almostWhite)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("\(title): \(text)")
            }
        }
    }
}

/// A row that displays a label and value pair, alongside an icon, for concise launch details.
struct LaunchDetailRow: View {
    let label: String
    let value: String
    let icon: String
    var iconColor: Color = ThemeColors.brightyellow
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.footnote) // match DetailItem icon size
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(ThemeColors.lightGray)
                    .accessibilityLabel("\(label):")
                
                Text(value)
                    .font(.subheadline) // match DetailItem text size
                    .foregroundColor(ThemeColors.almostWhite)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel("\(label): \(value)")
            }
        }
    }
}
struct ShimmerView: View {
    @State private var move = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.6),
                Color.white.opacity(0.1),
                Color.white.opacity(0.6)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 20)
        .mask(Rectangle())
        .rotationEffect(.degrees(20))
        .offset(x: move ? 200 : -200)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                move.toggle()
            }
        }
    }
}
