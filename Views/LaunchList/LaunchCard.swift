import SwiftUI

/// A card representing a single rocket launch, displaying an image, status, and description.
/// This component is designed to be displayed in a list or grid of upcoming launches.
struct LaunchCard: View {
    let launch: Launch
    
    // MARK: - Constants
    private enum Constants {
        static let imageHeight: CGFloat = 220
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let descriptionLineLimit = 2
        static let descriptionToggleThreshold = 100
        static let animationDuration = 0.4
        static let outlineWidth: CGFloat = 1
    }
    
    // MARK: - State
    @State private var hasAppeared = false
    @State private var imageLoaded = false
    @State private var showFullDescription = false
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            contentSection
        }
        .background(ThemeColors.spaceBlack)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .stroke(ThemeColors.darkGray.opacity(0.5), lineWidth: Constants.outlineWidth)
        )
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        .scaleEffect(hasAppeared ? 1.0 : 0.98)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .onAppear {
            // Animate card appearance using a spring animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                hasAppeared = true
            }
        }
        // Provide a descriptive accessibility label
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(launch.name) launch card.")
        .padding(.vertical, Constants.verticalPadding)
    }
    
    // MARK: - Image Section
    /// The top section that displays the launch image overlaid with a gradient, mission name, and status.
    @ViewBuilder
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            launchImage
            gradientOverlay
            
            VStack {
                HStack {
                    missionNameLabel
                        .accessibilityAddTraits(.isHeader) // Mark mission name as a heading for screen readers
                    Spacer()
                    statusTag
                }
                .padding(Constants.padding)
                
                Spacer()
            }
        }
    }
    
    /// Asynchronously loads and displays the launch image, showing placeholders during loading/failure states.
    private var launchImage: some View {
        AsyncImage(url: URL(string: launch.imageURL ?? "")) { phase in
            switch phase {
            case .empty:
                loadingPlaceholder
                    .transition(.opacity.animation(.easeInOut(duration: Constants.animationDuration)))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .onAppear {
                        withAnimation(.easeOut(duration: Constants.animationDuration)) {
                            imageLoaded = true
                        }
                    }
                    .scaleEffect(imageLoaded ? 1.0 : 0.95)
                    .opacity(imageLoaded ? 1.0 : 0.0)
                    .accessibilityLabel("Launch image for \(launch.name)")
            case .failure:
                errorPlaceholder
                    .accessibilityLabel("No image available for \(launch.name)")
            @unknown default:
                EmptyView()
            }
        }
        .frame(height: Constants.imageHeight)
        .clipped()
    }
    
    /// A vertical gradient overlay to ensure readability of text displayed over the image.
    private var gradientOverlay: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .clear,
                ThemeColors.spaceBlack.opacity(0.3),
                ThemeColors.spaceBlack.opacity(0.6),
                ThemeColors.spaceBlack
            ]),
            startPoint: UnitPoint(x: 0.5, y: -0.1),
            endPoint: UnitPoint(x: 0.5, y: 1.2)
        )
        .accessibilityHidden(true)
    }
    
    /// Mission name displayed at the top of the image section.
    private var missionNameLabel: some View {
        Text(launch.name)
            .font(.headline)
            .foregroundColor(ThemeColors.brightyellow)
            .lineLimit(2)
            .accessibilityHint("Name of the mission.")
    }
    
    /// A status tag representing the launch status.
    private var statusTag: some View {
        LaunchStatusTag(status: launch.status)
            .accessibilityHint("Launch status indicator.")
    }
    
    // MARK: - Content Section
    /// Displays the description and additional launch details below the image.
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            descriptionSection
            launchDetails
        }
        .padding([.horizontal, .bottom], Constants.padding)
    }
    
    /// Shows a short description of the launch, with a toggle if the description is lengthy.
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(launch.shortDescription)
                .font(.subheadline)
                .foregroundColor(ThemeColors.lightGray)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .lineLimit(showFullDescription ? nil : Constants.descriptionLineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Launch description: \(launch.shortDescription)")
            
            if launch.shortDescription.count > Constants.descriptionToggleThreshold {
                descriptionToggleButton
            }
        }
    }
    
    /// A button allowing the user to expand or collapse the description text.
    private var descriptionToggleButton: some View {
        Button {
            withAnimation(.easeInOut) {
                showFullDescription.toggle()
            }
        } label: {
            Text(showFullDescription ? "Show Less" : "Show More")
                .font(.caption)
                .foregroundColor(ThemeColors.brightyellow)
        }
        .accessibilityLabel("Toggle full description")
    }
    
    /// Displays key launch details like date, location, and time until launch.
    private var launchDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailItem(
                label: "Launch Date",
                value: launch.formattedDate,
                icon: "calendar"
            )
            Divider().background(ThemeColors.darkGray.opacity(0.3))
            DetailItem(
                label: "Location",
                value: launch.location,
                icon: "mappin.and.ellipse"
            )
            Divider().background(ThemeColors.darkGray.opacity(0.3))
            DetailItem(
                label: "Time Until Launch",
                value: launch.timeUntilLaunch,
                icon: "clock"
            )
        }
        .accessibilityLabel("Additional launch details")
    }
    
    // MARK: - Placeholder Views
    /// Placeholder shown while the launch image is being loaded.
    private var loadingPlaceholder: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [ThemeColors.darkGray, ThemeColors.midGray]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.85)
            
            VStack(spacing: 10) {
                ShimmerView(width: 160, height: 24)
                Text("Loading Launch...")
                    .font(.footnote.bold())
                    .foregroundColor(ThemeColors.brightyellow.opacity(0.9))
            }
        }
        .accessibilityHidden(true)
    }
    
    /// Placeholder shown if the image fails to load.
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay(
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(ThemeColors.lunarRock)
                        .font(.system(size: 40, weight: .bold))
                    
                    Text("Image Unavailable")
                        .font(.footnote.bold())
                        .foregroundColor(ThemeColors.lightGray)
                }
            )
            .accessibilityHidden(true)
    }
}
