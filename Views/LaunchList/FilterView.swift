import SwiftUI

struct FilterView: View {
    @Binding var criteria: LaunchCriteria
    
    @Environment(\.dismiss) var dismiss
    
    // Temporary states for filter controls
    @State private var selectedStatus: LaunchStatus?
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var filterLocation: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: Binding(
                        get: { startDate ?? Date() },
                        set: { startDate = $0 }
                    ), displayedComponents: .date)
                    
                    DatePicker("End Date", selection: Binding(
                        get: { endDate ?? Date().addingTimeInterval(24*60*60) },
                        set: { endDate = $0 }
                    ), displayedComponents: .date)
                }
                
                Section(header: Text("Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        Text("Any").tag(LaunchStatus?.none)
                        Text("Upcoming").tag(LaunchStatus?.some(.upcoming))
                        Text("Launching").tag(LaunchStatus?.some(.launching))
                        Text("Successful").tag(LaunchStatus?.some(.successful))
                        Text("Failed").tag(LaunchStatus?.some(.failed))
                        Text("Delayed").tag(LaunchStatus?.some(.delayed))
                        Text("Cancelled").tag(LaunchStatus?.some(.cancelled))
                    }
                }
                
                Section(header: Text("Location")) {
                    TextField("Enter location keyword", text: $filterLocation)
                }
            }
            .navigationTitle("Filter Launches")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        // Update criteria and dismiss
                        criteria = LaunchCriteria(
                            startDate: startDate,
                            endDate: endDate,
                            status: selectedStatus,
                            location: filterLocation.isEmpty ? nil : filterLocation
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
