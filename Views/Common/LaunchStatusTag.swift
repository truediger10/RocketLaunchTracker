// Views/Common/LaunchStatusTag.swift

import SwiftUI
import Foundation

/// A SwiftUI view that displays a tag representing the launch status.
struct LaunchStatusTag: View {
    let status: LaunchStatus

    var body: some View {
        Text(status.displayText)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    /// Determines the color based on the launch status.
    private var statusColor: Color {
        status.color // Utilize the color property from LaunchStatus
    }
}

// Preview for SwiftUI Canvas
struct LaunchStatusTag_Previews: PreviewProvider {
    static var previews: some View {
        LaunchStatusTag(status: LaunchStatus.upcoming)
            .padding()
    }
}
