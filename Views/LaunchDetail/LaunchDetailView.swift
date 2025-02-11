import SwiftUI
import Foundation

/// A SwiftUI view that displays detailed information about a rocket launch.
struct LaunchDetailView: View {
    // MARK: - Constants
    private enum Constants {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 16
        static let closeButtonSize: CGFloat = 20  // increased for better touch target
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
        .scrollContentBackground(.hidden) // Remove default scroll background.
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
    
    /// The hero section displaying the launch image with a gradient overlay and content.
    private var heroSection: some View {
        GeometryReader { geometry in
            let imageHeight = geometry.size.width * 0.75
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: launch.imageURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        loadingPlaceholder
                            .frame(width: geometry.size.width, height: imageHeight)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: imageHeight)
                            .clipped()
                            .onAppear { imageLoaded = true }
                            .transition(.opacity)
                    case .failure:
                        errorPlaceholder
                            .frame(width: geometry.size.width, height: imageHeight)
                    @unknown default:
                        EmptyView()
                    }
                }
                imageGradient
                    .frame(width: geometry.size.width, height: imageHeight)
                heroOverlayContent
                    .padding(Constants.padding)
            }
            .frame(height: imageHeight)
        }
    }
    
    /// A gradient overlay to improve text readability.
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
    }
    
    /// Overlay content on the hero image (provider, status badge, and time until launch).
    private var heroOverlayContent: some View {
        VStack(alignment: .leading, spacing: Constants.spacing / 2) {
            Text(launch.provider)
                .font(.headline)
                .foregroundColor(ThemeColors.brightYellow)
                .lineLimit(2)
            LaunchStatusBadgeView(launch: launch)
            Spacer()
            Text(launch.timeUntilLaunch)
                .font(.subheadline)
                .foregroundColor(ThemeColors.almostWhite)
        }
    }
    
    /// The main content section with title, details, mission overview, and badges.
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            titleSection
            ContentDivider()
            detailsSection
            ContentDivider()
            missionOverviewSection
            if let badges = launch.badges, !badges.isEmpty {
                HStack(spacing: Constants.spacing) {
                    ForEach(badges) { badge in
                        BadgeView(badge: badge)
                    }
                }
                .padding(.top, Constants.spacing)
            }
        }
        .padding(Constants.padding)
    }
    
    /// Displays the launch name.
    private var titleSection: some View {
        Text(launch.name)
            .font(.title2.bold())
            .foregroundColor(ThemeColors.almostWhite)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Displays detailed information such as launch date, location, rocket, orbit, and time until launch.
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacing * 1.5) {
            DetailItem(label: "Launch Date", value: launch.formattedDate, icon: "calendar.day.timeline.left")
            DetailItem(label: "Location", value: launch.location, icon: "mappin.and.ellipse")
            DetailItem(label: "Rocket", value: launch.rocketName, icon: "paperplane.fill")
            if let orbit = launch.orbit {
                DetailItem(label: "Orbit", value: orbit, icon: "globe.americas.fill")
            }
            DetailItem(label: "Time Until Launch", value: launch.timeUntilLaunch, icon: "timer")
        }
    }
    
    /// The mission overview section with expandable text.
    private var missionOverviewSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            missionOverviewHeader
            Text(launch.detailedDescription ?? "No description available")
                .foregroundColor(ThemeColors.lightGray)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(showFullMissionOverview ? nil : Constants.descriptionLineLimit)
                .animation(.easeInOut, value: showFullMissionOverview)
        }
    }
    
    /// Header for mission overview, including a toggle button for full text.
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
    
    /// A close button at the top-right corner.
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
    
    /// A placeholder view while the image is loading.
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay(ProgressView().tint(ThemeColors.brightYellow))
    }
    
    /// A placeholder view in case the image fails to load.
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay(
                Image(systemName: "paperplane.fill")
                    .foregroundColor(ThemeColors.lunarRock)
                    .font(.system(size: 60))
            )
    }
}
