import SwiftUI

struct LaunchCard: View {
    let launch: Launch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Container with fixed aspect ratio
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: launch.imageURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        loadingPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    case .failure:
                        errorPlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 200)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.4),
                            .clear,
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LaunchStatusTag(status: launch.status)
                    .padding([.top, .leading], 16)
            }
            
            // Content Container
            VStack(alignment: .leading, spacing: 16) {
                // Title and Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(launch.name)
                        .font(.headline)
                        .foregroundColor(ThemeColors.almostWhite)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(launch.shortDescription)
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.lightGray)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Launch Details
                VStack(alignment: .leading, spacing: 12) {
                    LaunchDetailRow(label: "Launch Date", value: launch.formattedDate, icon: "calendar")
                    LaunchDetailRow(label: "Location", value: launch.location, icon: "mappin.and.ellipse")
                    LaunchDetailRow(label: "Provider", value: launch.provider, icon: "airplane")
                }
            }
            .padding(16)
        }
        .background(ThemeColors.darkGray)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                ProgressView()
                    .tint(ThemeColors.brightyellow)
            }
    }
    
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(ThemeColors.darkGray)
            .overlay {
                Image(systemName: "rocket.fill")
                    .foregroundColor(ThemeColors.lunarRock)
                    .font(.system(size: 40))
            }
    }
}
