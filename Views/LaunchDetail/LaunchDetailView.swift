import SwiftUI

struct LaunchDetailView: View {
    let launch: Launch
    @Environment(\.dismiss) private var dismiss
    @State private var showSafariView = false
    @State private var safariURL: URL?
    
    // State for mission overview toggle
    @State private var showFullMissionOverview = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                VStack(alignment: .leading, spacing: 24) {
                    titleSection
                    
                    ZStack {
                        ThemeColors.darkGray.opacity(0.4)
                            .cornerRadius(12)
                        
                        // Add some horizontal padding inside to ensure left alignment feels correct
                        detailsSection
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    missionOverviewSection
                    learnMoreButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .background(ThemeColors.spaceBlack)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .sheet(isPresented: $showSafariView) {
            if let safariURL = safariURL {
                SafariView(url: safariURL)
            }
        }
    }
    
    private var heroSection: some View {
        ZStack(alignment: .top) {
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
                    case .failure:
                        errorPlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.width * 0.75)
            
            LinearGradient(
                colors: [
                    .black.opacity(0.7),
                    .black.opacity(0.3),
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            
            VStack(alignment: .leading, spacing: 12) {
                Text(launch.provider)
                    .font(.headline)
                    .foregroundColor(ThemeColors.brightyellow)
                
                LaunchStatusTag(status: launch.status)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ThemeColors.darkGray)
    }
    
    private var titleSection: some View {
        Text(launch.name)
            .font(.title2.bold())
            .foregroundColor(ThemeColors.almostWhite)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailItem(title: "Launch Date", icon: "calendar", text: launch.formattedDate)
            DetailItem(title: "Location", icon: "mappin.and.ellipse", text: launch.location)
            DetailItem(title: "Rocket", icon: "airplane", text: launch.rocketName)
            if let orbit = launch.orbit {
                DetailItem(title: "Orbit", icon: "circle.dashed", text: orbit)
            }
        }
    }
    
    private var missionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mission Overview")
                    .font(.headline)
                    .foregroundColor(ThemeColors.almostWhite)
                
                Spacer()
                
                // Toggle button for mission overview
                Button(action: {
                    withAnimation(.easeInOut) {
                        showFullMissionOverview.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(showFullMissionOverview ? "Show Less" : "Show More")
                            .font(.footnote)
                        Image(systemName: showFullMissionOverview ? "chevron.up" : "chevron.down")
                            .font(.footnote)
                    }
                    .foregroundColor(ThemeColors.brightyellow)
                }
            }
            
            // Conditional lineLimit based on showFullMissionOverview
            Text(launch.detailedDescription)
                .foregroundColor(ThemeColors.lightGray)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(showFullMissionOverview ? nil : 4)
                .animation(.easeInOut, value: showFullMissionOverview)
        }
    }
    
    private var learnMoreButton: some View {
        Group {
            if let wikiURL = launch.wikiURL,
               let url = URL(string: wikiURL) {
                Button {
                    safariURL = url
                    showSafariView = true
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Learn More")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThemeColors.brightyellow)
                    .foregroundColor(ThemeColors.spaceBlack)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ThemeColors.almostWhite)
                .padding(8)
                .background(Circle().fill(ThemeColors.darkGray.opacity(0.8)))
                .padding()
        }
    }
    
    // MARK: - Helper Views
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                ProgressView()
                    .tint(ThemeColors.brightyellow)
            }
            .aspectRatio(4/3, contentMode: .fill)
    }
    
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                Image(systemName: "rocket.fill")
                    .foregroundColor(ThemeColors.lunarRock)
                    .font(.system(size: 60))
            }
            .aspectRatio(4/3, contentMode: .fill)
    }
}
