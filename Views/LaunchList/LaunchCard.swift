
import SwiftUI

struct LaunchCard: View {
    let launch: Launch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Section
            Group {
                if let imageURL = launch.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(ThemeColors.brightyellow)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            Image("placeholderImage")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "airplane")
                        .font(.system(size: 40))
                        .foregroundColor(ThemeColors.lunarRock)
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(ThemeColors.darkGray)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 8)
            
            // Info Section
            VStack(alignment: .leading, spacing: 8) {
                Text(launch.name)
                    .font(.headline)
                    .foregroundColor(ThemeColors.almostWhite)
                    .padding(3)
                Text(launch.provider)
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.brightyellow)
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(ThemeColors.brightyellow)
                    Text(launch.formattedDate)
                        .font(.caption)
                        .foregroundColor(ThemeColors.lightGray)
                }
                HStack {
                    Image(systemName: "pin")
                        .foregroundColor(ThemeColors.brightyellow)
                    Text(launch.location)
                        .font(.caption)
                        .foregroundColor(ThemeColors.lightGray)
                }
                Text(launch.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.almostWhite)
                    .lineLimit(3)
                
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(ThemeColors.darkGray)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 8)
        }
    }
}
