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
        // Removed shadow-related constants if any
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
        // Removed shadow modifier
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(activityItems: shareContent)
        }
    }
    
    struct BadgesSection: View {
        let badges: [Badge]
        
        var body: some View {
            HStack(spacing: 8) {
                ForEach(badges, id: \.self) { badge in
                    Text(badge.displayText)
                        .font(.caption)
                        .padding(8)
                        .background(ThemeColors.darkGray)
                        .foregroundColor(ThemeColors.almostWhite)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Image Section
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
    
    private var overlayContent: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(launch.provider)
                        .font(.headline)
                        .foregroundColor(ThemeColors.brightYellow)
                    
                    LaunchStatusTag(status: launch.status)
                }
                
                Spacer()
                
                shareButton
            }
            .padding(Constants.padding)
            
            Spacer()
        }
    }
    
    private var shareButton: some View {
        Button(action: { isShareSheetPresented = true }) {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.white)
                .font(.system(size: 16))
                .padding(8)
                .background(ThemeColors.spaceBlack.opacity(0.3))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Content Section
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
            
            // Only display real badges if available
            if let badges = launch.badges {
                BadgesSection(badges: badges)
            }
        }
        .padding(Constants.padding)
    }
    
    private var titleSection: some View {
        Text(launch.name)
            .font(.title3.bold())
            .foregroundColor(ThemeColors.almostWhite)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailItem(
                label: "Launch Date",
                value: launch.formattedDate,
                icon: "calendar"
            )
            
            DetailItem(
                label: "Location",
                value: launch.location,
                icon: "mappin.circle"
            )
            
            DetailItem(
                label: "Time Until Launch",
                value: launch.timeUntilLaunch,
                icon: "timer"
            )
        }
    }
    
    // MARK: - Helper Properties
    private var shareContent: [Any] {
        var items: [Any] = [
            "\(launch.name)\nLaunch Date: \(launch.formattedDate)\nProvider: \(launch.provider)"
        ]
        if let imageURL = launch.imageURL, let url = URL(string: imageURL) {
            items.append(url)
        }
        return items
    }
}
