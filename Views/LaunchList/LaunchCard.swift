import SwiftUI

struct LaunchCard: View {
    let launch: Launch
    
    @State private var showShareSheet = false
    @State private var imageLoaded = false

    private enum Constants {
        static let imageHeight: CGFloat = 160
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 12
        static let verticalSpacing: CGFloat = 8
        static let detailSpacing: CGFloat = 12
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            contentSection
        }
        .background(ThemeColors.spaceBlack)
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: ThemeColors.darkGray.opacity(0.6), radius: 4, x: 0, y: 2)
        .padding(.horizontal, Constants.padding)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareContent)
        }
    }

    // MARK: - Image Section
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            LaunchImageView(imageURL: launch.imageURL, height: Constants.imageHeight) {
                // Removed or replaced the short fade animation with a simpler approach
                imageLoaded = true
            }
            
            
            // Share button in the top-right corner
            Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(ThemeColors.darkGray.opacity(0.7))
                    .clipShape(Circle())
            }
            .padding(Constants.padding)
        }
    }

    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            // Provider (e.g., "SpaceX")
            Text(launch.provider)
                .font(.subheadline)
                .foregroundColor(ThemeColors.brightYellow)
            
            // Mission Name by itself
            Text(launch.name)  // e.g. "Starlink Group 12-8"
                .font(.headline)
                .foregroundColor(ThemeColors.almostWhite)
                .lineLimit(2)
            
            // Status Tag - commented out as requested
            // LaunchStatusTag(status: launch.status)
            // Card details: Rocket, Date, Location, Time
            VStack(alignment: .leading, spacing: Constants.detailSpacing) {
                // If your model has rocketName = "Falcon 9 Block 5"
                DetailItem(label: "Rocket", value: launch.rocketName, icon: "paperplane.fill")
                
                DetailItem(label: "Date", value: launch.formattedDate, icon: "calendar")
                DetailItem(label: "Location", value: launch.location, icon: "mappin.and.ellipse")
                
                Text("Time: \(launch.timeUntilLaunch)")
                    .font(.footnote)
                    .foregroundColor(ThemeColors.lightGray)
            }
        }
        .padding(Constants.padding)
    }

    // MARK: - Sharing Content
    private var shareContent: [Any] {
        var items: [Any] = [
            "\(launch.name)\nDate: \(launch.formattedDate)\nProvider: \(launch.provider)"
        ]
        if let urlString = launch.imageURL, let url = URL(string: urlString) {
            items.append(url)
        }
        return items
    }
}
