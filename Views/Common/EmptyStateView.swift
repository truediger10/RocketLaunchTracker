import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rocket")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No Launches Available")
                .font(.title2)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
