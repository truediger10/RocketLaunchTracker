import SwiftUI

struct LaunchDetailView: View {
    let launch: Launch
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSafariView = false
    @State private var safariURL: URL?
    @State private var showFullMissionOverview = false
    @State private var imageLoaded = false

    private enum Constants {
        static let padding: CGFloat = 16
        static let imageAspectRatio: CGFloat = 0.75
        static let closeButtonSize: CGFloat = 16
        static let descriptionLineLimit = 2
    }
    
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
            if let url = safariURL {
                SafariView(url: url)
            }
        }
    }
    
    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            LaunchImageView(imageURL: launch.imageURL, height: UIScreen.main.bounds.width * Constants.imageAspectRatio) {
                withAnimation { imageLoaded = true }
            }
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
            heroOverlayContent
        }
    }
    
    private var heroOverlayContent: some View {
        VStack(alignment: .leading) {
            // Display the provider from the mapped data
            Text(launch.provider)
                .font(.headline)
                .foregroundColor(ThemeColors.brightYellow)
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
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Constants.padding) {
            Text(launch.name)
                .font(.title2.bold())
                .foregroundColor(ThemeColors.almostWhite)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
                .background(ThemeColors.darkGray)
            
            VStack(alignment: .leading, spacing: 12) {
                DetailItem(label: "Launch Date", value: launch.formattedDate, icon: "calendar.day.timeline.left")
                DetailItem(label: "Location", value: launch.location, icon: "mappin.and.ellipse")
                DetailItem(label: "Rocket", value: launch.rocketName, icon: "paperplane.fill")
                if let orbit = launch.orbit {
                    DetailItem(label: "Orbit", value: orbit, icon: "globe.americas.fill")
                }
                DetailItem(label: "Time Until Launch", value: launch.timeUntilLaunch, icon: "timer")
            }
            
            Divider()
                .background(ThemeColors.darkGray)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mission Overview")
                        .font(.headline)
                        .foregroundColor(ThemeColors.almostWhite)
                    Spacer()
                    Button {
                        withAnimation { showFullMissionOverview.toggle() }
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
                
                Text(launch.detailedDescription ?? "No description available")
                    .foregroundColor(ThemeColors.lightGray)
                    .lineLimit(showFullMissionOverview ? nil : Constants.descriptionLineLimit)
                    .animation(.easeInOut, value: showFullMissionOverview)
            }
            
            if let wiki = launch.wikiURL, let url = URL(string: wiki) {
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
                    .cornerRadius(8)
                }
            }
            
            if let badges = launch.badges, !badges.isEmpty {
                HStack(spacing: 8) {
                    ForEach(badges) { badge in
                        BadgeView(badge: badge)
                    }
                }
                .padding(.top, Constants.padding)
            }
        }
        .padding(Constants.padding)
    }
    
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
}
