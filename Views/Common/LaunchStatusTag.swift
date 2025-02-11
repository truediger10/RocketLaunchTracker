/// A SwiftUI view that displays a tag representing the launch status.

import SwiftUICore
struct LaunchStatusTag: View {
    let status: LaunchStatus

    var body: some View {
        Text(status.displayText)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color) // Uses the computed property from LaunchStatus
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
