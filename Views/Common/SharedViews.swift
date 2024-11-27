import SwiftUI

struct LaunchImageView: View {
    let imageURL: String?

    var body: some View {
        if let imageURL = imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { image in
                image.resizable()
                     .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
        } else {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
        }
    }
}
