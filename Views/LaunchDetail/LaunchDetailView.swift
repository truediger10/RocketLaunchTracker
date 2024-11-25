import SwiftUI

struct LaunchDetailView: View {
    let launch: Launch
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Section
                AsyncImage(url: URL(string: launch.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(ThemeColors.darkGray)
                        .overlay {
                            Image(systemName: "rocket")
                                .foregroundColor(ThemeColors.lunarRock)
                                .font(.system(size: 40))
                        }
                }
                .frame(height: 300)
                .clipped()
                
                // Content Section
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(launch.name)
                            .font(.title)
                            .foregroundColor(ThemeColors.almostWhite)
                        
                        Text(launch.provider)
                            .font(.subheadline)
                            .foregroundColor(ThemeColors.lightGray)
                    }
                    
                    // Launch Info
                    InfoRow(title: "Date", value: launch.formattedDate)
                    InfoRow(title: "Location", value: launch.location)
                    InfoRow(title: "Rocket", value: launch.rocketName)
                    if let orbit = launch.orbit {
                        InfoRow(title: "Orbit", value: orbit)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mission Details")
                            .font(.headline)
                            .foregroundColor(ThemeColors.almostWhite)
                        
                        Text(launch.detailedDescription)
                            .foregroundColor(ThemeColors.lightGray)
                    }
                    .padding()
                    .background(ThemeColors.darkGray)
                    .cornerRadius(12)
                    
                    // Wiki Link if available
                    if let wikiURL = launch.wikiURL,
                       let url = URL(string: wikiURL) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Learn More")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ThemeColors.brightyellow)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .background(ThemeColors.spaceBlack)
        .ignoresSafeArea(.all, edges: .top)
        .overlay(closeButton, alignment: .topTrailing)
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundColor(ThemeColors.almostWhite)
                .padding()
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(ThemeColors.lightGray)
            Text(value)
                .font(.body)
                .foregroundColor(ThemeColors.almostWhite)
        }
    }
}
