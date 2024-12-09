// Inside LaunchCard.swift

import SwiftUI

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
        static let shareButtonPadding: CGFloat = 12 // New constant for share button padding
    }
    
    // MARK: - State
    @State private var hasAppeared = false
    @State private var imageLoaded = false
    @State private var showFullDescription = false
    @State private var isShareSheetPresented = false // New State Variable
    @State private var isShareButtonPressed = false // New State Variable for Button Press Animation
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            contentSection
            // Removed shareButton from here
        }
        .background(ThemeColors.spaceBlack)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .stroke(ThemeColors.darkGray.opacity(0.5), lineWidth: Constants.outlineWidth)
        )
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        .rotationEffect(hasAppeared ? .degrees(0) : .degrees(-5))
        .opacity(hasAppeared ? 1.0 : 0.7)
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
        // Present the Share Sheet when isShareSheetPresented is true
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(activityItems: shareContent)
        }
    }
    
    // MARK: - Share Content
    private var shareContent: [Any] {
        let launchDetails = """
        🚀 Launch: \(launch.name)
        📅 Date: \(launch.formattedDate)
        📍 Location: \(launch.location)
        
        \(launch.shortDescription)
        
        Learn more at: https://yourapp.com/launch/\(launch.id)
        """
        
        if let imageURLString = launch.imageURL, let url = URL(string: imageURLString) {
            return [launchDetails, url]
        }
        
        return [launchDetails]
    }
    
    // MARK: - Share Button (Overlayed on Image)
    private var shareButton: some View {
        Button(action: {
            isShareSheetPresented = true
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold)) // Adjusted icon size for consistency
                Text("Share")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(8)
            .foregroundColor(ThemeColors.brightYellow)
            .frame(minWidth: 44, minHeight: 44) // Ensure sufficient touch target
            .scaleEffect(isShareButtonPressed ? 0.95 : 1.0)
            .animation(.spring(), value: isShareButtonPressed)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .shadow(radius: 2)
            .accessibilityLabel("Share launch details")
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isShareButtonPressed = true
                }
                .onEnded { _ in
                    isShareButtonPressed = false
                }
        )
        .padding(Constants.shareButtonPadding)
    }
    
    // MARK: - Image Section
    /// The top section that displays the launch image overlaid with a gradient, mission name, status, and badges.
    @ViewBuilder
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            launchImage
                .cornerRadius(Constants.cornerRadius)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2) // Rounded corners and shadow
            
            gradientOverlay
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) { // Center elements vertically
                    missionInfoLabel
                    Spacer()
                }
                .padding(Constants.padding)
                
                // Display badges if available
                if let badges = launch.badges, !badges.isEmpty {
                    HStack(spacing: 8) { // Use HStack to layout multiple badges
                        ForEach(badges) { badge in
                            BadgeView(badge: badge)
                        }
                    }
                    .padding([.horizontal, .bottom], Constants.padding)
                }
                
                Spacer()
            }
            
            // Share button overlayed at the bottom-right corner of the image
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    shareButton
                }
            }
        }
    }
    
    /// Mission provider displayed above the mission name.
    private var missionProviderLabel: some View {
        Text(launch.provider)
            .font(.caption) // Adjusted font size for better hierarchy
            .fontWeight(.regular)
            .foregroundColor(ThemeColors.lightGray)
            .lineLimit(1)
            .accessibilityLabel("Mission provider: \(launch.provider)")
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
    private var heroOverlayContent: some View {
            VStack(alignment: .leading, spacing: 8) {
                missionInfoLabel
                    .padding([.leading, .top], Constants.padding)

                LaunchStatusTag(status: launch.status)
                    .padding(.leading, Constants.padding)

                Spacer()

                Text(launch.timeUntilLaunch)
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.almostWhite)
                    .padding([.leading, .bottom], Constants.padding)
            }
        }
    private var missionInfoLabel: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(launch.provider)
                    .font(.headline)
                    .foregroundColor(ThemeColors.brightYellow)

                Text(launch.name)
                    .font(.title2.bold())
                    .foregroundColor(ThemeColors.almostWhite)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
                .font(.subheadline) // Adjusted font for better readability
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
                .foregroundColor(ThemeColors.brightYellow)
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
            Divider().background(ThemeColors.darkGray.opacity(0.6)) // Adjusted opacity for better contrast
            DetailItem(
                label: "Location",
                value: launch.location,
                icon: "mappin.and.ellipse"
            )
            Divider().background(ThemeColors.darkGray.opacity(0.6))
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
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(ThemeColors.darkGray.opacity(0.85))
                .shadow(radius: 2)
            
            VStack(spacing: 10) {
                ShimmerView(width: 160, height: 24)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                ProgressView() // Added Progress Indicator
                    .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.brightYellow))
                    .scaleEffect(1.5)
                Text("Loading Launch...")
                    .font(.footnote.bold())
                    .foregroundColor(ThemeColors.brightYellow.opacity(0.9))
            }
        }
        .cornerRadius(Constants.cornerRadius)
        .shadow(radius: 2)
        .accessibilityHidden(true)
    }
    
    /// Placeholder shown if the image fails to load.
    private var errorPlaceholder: some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius)
            .fill(ThemeColors.darkGray)
            .shadow(radius: 2)
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
