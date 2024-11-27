import SwiftUI

@main
struct RocketLaunchTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LaunchListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
