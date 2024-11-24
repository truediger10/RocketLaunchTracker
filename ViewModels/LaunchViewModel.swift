import SwiftUI

@MainActor
class LaunchViewModel: ObservableObject {
    @Published private(set) var launches: [Launch] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let apiManager = APIManager.shared
    
    func fetchLaunches() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            print("🚀 Fetching launches...")
            launches = try await apiManager.fetchLaunches()
            print("📱 Received \(launches.count) launches")
            if launches.isEmpty {
                error = "No launches found"
            }
        } catch {
            print("❌ Error fetching launches: \(error.localizedDescription)")
            self.error = error.localizedDescription
            launches = []
        }
        
        isLoading = false
    }
}
