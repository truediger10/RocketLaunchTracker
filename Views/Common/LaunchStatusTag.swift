import SwiftUI

struct LaunchStatusTag: View {
    let status: LaunchStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(6)
            .background(status.color)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}

extension LaunchStatus {
    var color: Color {
        switch self {
        case .go:
            return .green
        case .tbd:
            return .orange
        case .success:
            return .blue
        case .failure:
            return .red
        case .hold:
            return .yellow
        case .inFlight:
            return .purple
        case .partialFailure:
            return .pink
        case .other:
            return .gray
        }
    }
}
