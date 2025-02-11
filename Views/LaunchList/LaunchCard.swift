import SwiftUI

struct LaunchCard: View {
    let launch: Launch
    
    // MARK: - Constants
    private enum Constants {
        static let imageHeight: CGFloat = 180
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 8
        static let descriptionLineLimit = 2
    }
    
    // MARK: - State
    @State private var showFullDescription = false
    @State private var isShareSheetPresented = false
    @State private var imageLoaded = false
    
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
                .stroke(ThemeColors.darkGray.opacity(0.5), lineWidth: 1)
        )
        .contentShape(Rectangle())  // Make entire card tappable.
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(activityItems: shareContent)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Launch card for \(launch.name)")
    }
    
    /// The image section displaying the launch image with an overlay.
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            LaunchImageView(
                imageURL: launch.imageURL,
                height: Constants.imageHeight
            ) {
                withAnimation(.easeOut(duration: 0.3)) {
                    imageLoaded = true
                }
            }
            overlayContent
        }
    }
    
    /// Overlay content (provider, status badge, and share button) on the image.
    private var overlayContent: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: Constants.spacing / 2) {
                    Text(launch.provider)
                        .font(.headline)
                        .foregroundColor(ThemeColors.brightYellow)
                        .accessibilityLabel("Provider: \(launch.provider)")
                    LaunchStatusBadgeView(launch: launch)
                }
                Spacer()
                shareButton
            }
            .padding(Constants.padding)
            Spacer()
        }
    }
    
    /// Button to trigger the share sheet.
    private var shareButton: some View {
        Button {
            isShareSheetPresented = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.white)
                .font(.system(size: 16))
                .padding(Constants.spacing)
                .background(ThemeColors.spaceBlack.opacity(0.3))
                .cornerRadius(8)
        }
        .accessibilityLabel("Share launch details")
        .accessibilityHint("Opens share sheet with details about \(launch.name)")
    }
    
    /// The content section containing title, details, mission overview, and badges.
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            titleSection
            ContentDivider()
            detailsSection
            ContentDivider()
            ExpandableText(
                text: launch.shortDescription ?? "No description available",
                title: "Mission Overview",
                isExpanded: $showFullDescription,
                lineLimit: Constants.descriptionLineLimit
            )
            if let badges = launch.badges, !badges.isEmpty {
                BadgesSection(badges: badges)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Launch badges")
            }
        }
        .padding(Constants.padding)
    }
    
    /// Displays the launch name.
    private var titleSection: some View {
        Text(launch.name)
            .font(.title3.bold())
            .foregroundColor(ThemeColors.almostWhite)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Shows details like launch date, location, and time until launch.
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Constants.spacing * 1.5) {
            DetailItem(label: "Launch Date", value: launch.formattedDate, icon: "calendar")
            DetailItem(label: "Location", value: launch.location, icon: "mappin.circle")
            DetailItem(label: "Time Until Launch", value: launch.timeUntilLaunch, icon: "timer")
        }
        .accessibilityElement(children: .combine)
    }
    
    /// Generates shareable content.
    private var shareContent: [Any] {
        var items: [Any] = [
            "\(launch.name)\nLaunch Date: \(launch.formattedDate)\nProvider: \(launch.provider)"
        ]
        if let imageURL = launch.imageURL, let url = URL(string: imageURL) {
            items.append(url)
        }
        return items
    }
    
    /// A view that displays a row of badges.
    struct BadgesSection: View {
        let badges: [Badge]
        var body: some View {
            HStack(spacing: Constants.spacing) {
                ForEach(badges, id: \.self) { badge in
                    Text(badge.displayText)
                        .font(.caption)
                        .padding(Constants.spacing)
                        .background(ThemeColors.darkGray)
                        .foregroundColor(ThemeColors.almostWhite)
                        .clipShape(Capsule())
                        .accessibilityLabel("\(badge.displayText) badge")
                }
            }
        }
    }
}
