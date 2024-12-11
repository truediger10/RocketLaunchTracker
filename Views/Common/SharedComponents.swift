import SwiftUI

/// Shared launch image view with consistent loading and error states
struct LaunchImageView: View {
    let imageURL: String?
    let height: CGFloat
    var onImageLoaded: (() -> Void)?
    
    // MARK: - Constants
    private enum Constants {
        static let gradientColors: [Color] = [
            .clear,
            ThemeColors.spaceBlack.opacity(0.3),
            ThemeColors.spaceBlack.opacity(0.6),
            ThemeColors.spaceBlack
        ]
        static let errorIconSize: CGFloat = 60
        static let aspectRatio: CGFloat = 16/9
        static let cornerRadius: CGFloat = 12
    }
    
    var body: some View {
        ZStack {
            imageContent
            gradientOverlay
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
    
    private var imageContent: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    loadingPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .onAppear {
                            onImageLoaded?()
                        }
                        .transition(.opacity)
                case .failure:
                    errorPlaceholder
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
    
    private var gradientOverlay: some View {
        LinearGradient(
            gradient: Gradient(colors: Constants.gradientColors),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var loadingPlaceholder: some View {
        ShimmerView(
            width: UIScreen.main.bounds.width,
            height: height
        )
    }
    
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(ThemeColors.lunarRock)
                    .font(.system(size: Constants.errorIconSize))
            }
    }
}


/// Generic detail item component for displaying labeled information
struct DetailItem: View {
    let label: String
    let value: String
    let icon: String?
    var iconColor: Color = ThemeColors.brightYellow
    
    // MARK: - Constants
    private enum Constants {
        static let iconSize: CGFloat = 20
        static let spacing: CGFloat = 8
        static let lineSpacing: CGFloat = 2
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: Constants.spacing) {
            iconView
            contentView
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let icon {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.footnote)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .accessibilityHidden(true)
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: Constants.lineSpacing) {
            Text(label)
                .font(.caption)
                .foregroundColor(ThemeColors.lightGray)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(ThemeColors.almostWhite)
                .lineSpacing(Constants.lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Shared content divider with consistent styling
struct ContentDivider: View {
    var body: some View {
        Divider()
            .background(ThemeColors.darkGray.opacity(0.6))
    }
}

/// Expandable text section with show more/less functionality
struct ExpandableText: View {
    let text: String
    let title: String
    @Binding var isExpanded: Bool
    var lineLimit: Int = 2
    
    @State private var textHeight: CGFloat = 0
    @State private var limitedHeight: CGFloat = 0
    @State private var hasOverflow: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ThemeColors.almostWhite)
                
                Spacer()
                
                if hasOverflow {
                    Button {
                        withAnimation(.easeInOut) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Show Less" : "Show More")
                                .font(.caption)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(ThemeColors.brightYellow)
                    }
                }
            }
            
            Text(text)
                .foregroundColor(ThemeColors.lightGray)
                .lineLimit(isExpanded ? nil : lineLimit)
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: HeightPreferenceKey.self,
                            value: geometry.size.height
                        )
                    }
                )
                .onPreferenceChange(HeightPreferenceKey.self) { height in
                    textHeight = height
                    hasOverflow = textHeight > limitedHeight
                }
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


/// Animated shimmer effect for loading states
struct ShimmerView: View {
    let width: CGFloat
    let height: CGFloat
    var duration: Double = 1.0
    var angle: Double = 20
    
    @State private var move = false
    
    private let gradient = Gradient(colors: [
        .white.opacity(0.1),
        .white.opacity(0.3),
        .white.opacity(0.1)
    ])
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: gradient,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 2, height: height)
            .rotationEffect(.degrees(angle))
            .offset(x: move ? width : -width)
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
        .clipped()
        .drawingGroup()
        .accessibilityHidden(true)
    }
}
