import SwiftUICore
import SwiftUI

// MARK: - ErrorView

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
                .opacity(0.9)
        )
        .cornerRadius(Constants.cornerRadius)
        .padding()
    }
    
    // MARK: - Subviews
    private var errorIcon: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: Constants.iconSize, weight: .bold))
            .foregroundColor(ThemeColors.brightYellow)
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
                .background(ThemeColors.brightYellow)
                .cornerRadius(Constants.buttonCornerRadius)
                .padding(.horizontal, Constants.buttonHorizontalPadding)
        }
        .accessibilityHint("Tap to try again")
    }
}
