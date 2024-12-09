import SwiftUI

/// Displays error state with retry functionality
struct ErrorView: View {
    // MARK: - Properties
    let error: String
    let retry: () -> Void
    
    // MARK: - Constants
    private enum Constants {
        static let iconSize: CGFloat = 50
        static let spacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 40
        static let buttonHorizontalPadding: CGFloat = 60
        static let cornerRadius: CGFloat = 20
        static let buttonCornerRadius: CGFloat = 10
        static let shadowRadius: CGFloat = 10
        static let shadowOffset: CGFloat = 5
        static let backgroundOpacity: Double = 0.9
        static let shadowOpacity: Double = 0.5
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.spacing) {
            errorIcon
            errorMessage
            retryButton
        }
        .padding()
        .background(
            ThemeColors.darkGray
                .opacity(Constants.backgroundOpacity)
        )
        .cornerRadius(Constants.cornerRadius)
        .shadow(
            color: ThemeColors.lunarRock.opacity(Constants.shadowOpacity),
            radius: Constants.shadowRadius,
            x: 0,
            y: Constants.shadowOffset
        )
        .padding()
    }
    
    // MARK: - Subviews
    private var errorIcon: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: Constants.iconSize, weight: .bold))
            .foregroundColor(ThemeColors.brightyellow)
            .accessibilityHidden(true)
    }
    
    private var errorMessage: some View {
        Text(error)
            .font(.headline)
            .foregroundColor(ThemeColors.almostWhite)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Constants.horizontalPadding)
            .accessibilityLabel("Error: \(error)")
    }
    
    private var retryButton: some View {
        Button(action: retry) {
            Text("Retry")
                .font(.subheadline.bold())
                .foregroundColor(ThemeColors.spaceBlack)
                .padding()
                .frame(maxWidth: .infinity)
                .background(ThemeColors.brightyellow)
                .cornerRadius(Constants.buttonCornerRadius)
                .padding(.horizontal, Constants.buttonHorizontalPadding)
        }
        .accessibilityHint("Tap to try again")
    }
}

// MARK: - Preview Provider
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorView(
                error: "Unable to load launch data",
                retry: {}
            )
            .preferredColorScheme(.dark)
            
            ErrorView(
                error: "Network connection lost",
                retry: {}
            )
            .environment(\.sizeCategory, .accessibilityLarge)
            .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.black)
    }
}
