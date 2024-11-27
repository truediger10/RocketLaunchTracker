import SwiftUI

struct LaunchCard: View {
    let launch: Launch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LaunchImageView(imageURL: launch.imageURL)
                .frame(height: 150)
                .clipped()
                .cornerRadius(8)

            Text(launch.name)
                .font(.headline)

            Text("Launch Date: \(launch.launchDate ?? "Unknown")")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LaunchStatusTag(status: launch.status)
        }
    }
}
