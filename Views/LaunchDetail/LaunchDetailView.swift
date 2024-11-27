import SwiftUI

struct LaunchDetailView: View {
    let launch: Launch

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LaunchImageView(imageURL: launch.imageURL)
                    .frame(height: 200)
                    .clipped()

                Text(launch.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)

                LaunchStatusTag(status: launch.status)
                    .padding(.horizontal)

                if let shortDescription = launch.shortDescription {
                    Text(shortDescription)
                        .font(.body)
                        .padding(.horizontal)
                }

                if let detailedDescription = launch.detailedDescription {
                    Text(detailedDescription)
                        .font(.body)
                        .padding(.horizontal)
                }

                // Additional details can be added here
            }
        }
        .navigationTitle("Launch Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
