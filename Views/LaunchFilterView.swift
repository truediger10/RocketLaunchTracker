import SwiftUI

struct LaunchFilterView: View {
    @Binding var selectedStatus: LaunchStatus?
    @Binding var selectedProvider: String?

    var body: some View {
        Form {
            Section(header: Text("Status")) {
                Picker("Status", selection: $selectedStatus) {
                    Text("All").tag(LaunchStatus?.none)
                    ForEach(LaunchStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(LaunchStatus?.some(status))
                    }
                }
            }

            Section(header: Text("Provider")) {
                // Replace with actual provider list if available
                Picker("Provider", selection: $selectedProvider) {
                    Text("All").tag(String?.none)
                    Text("SpaceX").tag(String?.some("SpaceX"))
                    Text("NASA").tag(String?.some("NASA"))
                    // Add more providers as needed
                }
            }
        }
        .navigationTitle("Filters")
    }
}
