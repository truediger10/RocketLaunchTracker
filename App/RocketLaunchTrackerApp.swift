import SwiftUI

@main
struct RocketLaunchTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchListView()
                .preferredColorScheme(.dark)
        }
    }
}
