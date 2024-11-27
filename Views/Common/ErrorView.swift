import SwiftUI

struct ErrorView: View {
    let error: APIError
    let retryAction: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.red)
            Text(error.localizedDescription)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            Button(action: {
                Task {
                    await retryAction()
                }
            }) {
                Text("Retry")
                    .font(.headline)
                    .padding()
                    .background(Color.red.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
