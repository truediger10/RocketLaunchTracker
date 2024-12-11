import SwiftUI

@main
struct RocketLaunchTrackerApp: App {
    init() {
            print("🚀 RocketLaunchTrackerApp initialized")
        }
    var body: some Scene {
        WindowGroup {
            LaunchTabView()
                .onAppear {
                    print("🪐 LaunchTabView appeared")
                }
        }
    }
}
