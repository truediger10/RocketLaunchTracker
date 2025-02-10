// Views/LaunchDetail/LaunchDetailView.swift

import SwiftUI
import Foundation

/// A SwiftUI view that displays detailed information about a rocket launch.
struct LaunchDetailView: View {
    // MARK: - Constants
    private enum Constants {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 16
        static let imageAspectRatio: CGFloat = 0.75
        static let closeButtonSize: CGFloat = 16
        static let descriptionLineLimit = 2
        static let cornerRadius: CGFloat = 8
    }

    // MARK: - Properties
    let launch: Launch
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var showSafariView = false
    @State private var safariURL: URL?
    @State private var showFullMissionOverview = false
    @State private var imageLoaded = false

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                contentSection
            }
        }
        .background(ThemeColors.spaceBlack)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) { closeButton }
        .sheet(isPresented: $showSafariView) {
            if let safariURL = safariURL {
                SafariView(url: safariURL)
            }
        }
    }

    // MARK: - Content Sections

    /// The main content section containing title, details, mission overview, badges, and share buttons.
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            titleSection
            contentDivider

            detailsSection
            contentDivider

            missionOverviewSection

            if hasLearnMore {
                contentDivider
                learnMoreButton

                if let twitterURLString = launch.twitterURL,
                   let validTwitterURL = URL(string: twitterURLString) {
                    shareSection(url: validTwitterURL)
                }
            }

            // Display Badges if available
            if let badges = launch.badges, !badges.isEmpty {
                HStack(spacing: 8) {
                    ForEach(badges) { badge in
                        BadgeView(badge: badge)
                    }
                }
                .padding(.top, 16)
            }
        }
        .padding(.horizontal, Constants.padding)
        .padding(.vertical, Constants.padding)
    }

    /// The hero section displaying the launch image with a gradient and overlay content.
    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            launchImage
            imageGradient
            heroOverlayContent
        }
    }

    /// Asynchronously loads and displays the launch image.
    private var launchImage: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: launch.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    loadingPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .onAppear { imageLoaded = true }
                        .transition(.opacity)
                case .failure:
                    errorPlaceholder
                @unknown default:
                    EmptyView()
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width * Constants.imageAspectRatio)
    }

    /// A gradient overlay for the launch image to enhance text readability.
    private var imageGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .clear,
                ThemeColors.spaceBlack.opacity(0.3),
                ThemeColors.spaceBlack.opacity(0.6),
                ThemeColors.spaceBlack
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: UIScreen.main.bounds.width * Constants.imageAspectRatio)
    }

    /// Overlay content on the hero section, including provider, status tag, and time until launch.
    private var heroOverlayContent: some View {
        VStack(alignment: .leading) {
            Text(launch.provider)
                .font(.headline)
                .foregroundColor(ThemeColors.brightYellow)
                .lineLimit(2)
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

    /// The title section displaying the launch name.
    private var titleSection: some View {
        Text(launch.name)
            .font(.title2.bold())
            .foregroundColor(ThemeColors.almostWhite)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The details section displaying various launch details.
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailItem(label: "Launch Date", value: launch.formattedDate, icon: "calendar.day.timeline.left")
            DetailItem(label: "Location", value: launch.location, icon: "mappin.and.ellipse")
            DetailItem(label: "Rocket", value: launch.rocketName, icon: "paperplane.fill") // Accessing rocketName
            if let orbit = launch.orbit {
                DetailItem(label: "Orbit", value: orbit, icon: "globe.americas.fill")
            }
            DetailItem(label: "Time Until Launch", value: launch.timeUntilLaunch, icon: "timer")
        }
    }

    /// The mission overview section with expandable text.
    private var missionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            missionOverviewHeader

            Text(launch.detailedDescription ?? "No description available")
                .foregroundColor(ThemeColors.lightGray)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(showFullMissionOverview ? nil : Constants.descriptionLineLimit)
                .animation(.easeInOut, value: showFullMissionOverview)
        }
    }

    /// The header for the mission overview section, including a toggle button.
    private var missionOverviewHeader: some View {
        HStack {
            Text("Mission Overview")
                .font(.headline)
                .foregroundColor(ThemeColors.almostWhite)

            Spacer()

            Button {
                withAnimation(.easeInOut) {
                    showFullMissionOverview.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(showFullMissionOverview ? "Show Less" : "Show More")
                        .font(.caption)
                    Image(systemName: showFullMissionOverview ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(ThemeColors.brightYellow)
            }
        }
    }

    /// A divider used between content sections.
    private var contentDivider: some View {
        Divider()
            .background(ThemeColors.darkGray.opacity(0.6))
    }

    /// The learn more button that opens a Safari view with the provided wiki URL.
    private var learnMoreButton: some View {
        Group {
            if let wikiURL = launch.wikiURL, let url = URL(string: wikiURL) {
                Button {
                    safariURL = url
                    showSafariView = true
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.caption)
                        Text("Learn More")
                            .font(.caption)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(ThemeColors.brightYellow)
                    .foregroundColor(ThemeColors.spaceBlack)
                    .cornerRadius(Constants.cornerRadius)
                }
            }
        }
    }

    /// The share section containing the Tweet button.
    @ViewBuilder
    private func shareSection(url: URL) -> some View {
        TweetButtonView(
            text: "Check out this launch!",
            url: url,
            hashtags: "",
            via: ""
        )
        .frame(height: 120)
        .padding(.top, 8)
    }

    /// The close button to dismiss the view.
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: Constants.closeButtonSize, weight: .bold))
                .foregroundColor(ThemeColors.almostWhite)
                .padding(8)
                .background(Circle().fill(ThemeColors.darkGray.opacity(0.8)))
                .padding()
        }
    }

    /// Placeholder view displayed while the launch image is loading.
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                ProgressView()
                    .tint(ThemeColors.brightYellow)
            }
            .aspectRatio(4/3, contentMode: .fill)
    }

    /// Placeholder view displayed if the launch image fails to load.
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(ThemeColors.lunarRock)
                    .font(.system(size: 60))
            }
            .aspectRatio(4/3, contentMode: .fill)
    }

    /// Determines whether the learn more section should be displayed.
    private var hasLearnMore: Bool {
        guard let wikiURL = launch.wikiURL,
              URL(string: wikiURL) != nil else {
            return false
        }
        return true
    }
}

// Preview for SwiftUI Canvas
struct LaunchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchDetailView(launch: Launch(
            id: "1",
            name: "Test Launch",
            net: Date(),
            status: .upcoming, // Using enum case directly
            rocket: "Falcon 9",
            provider: "SpaceX",
            location: "Cape Canaveral",
            imageURL: "https://example.com/image.jpg",
            shortDescription: "Short description",
            detailedDescription: "Detailed mission overview.",
            orbit: "LEO",
            wikiURL: "https://en.wikipedia.org/wiki/Falcon_9",
            twitterURL: "https://twitter.com/SpaceX",
            badges: [.live, .exclusive] // Explicitly specify the enum type
        ))
    }
}
