import SwiftUI

struct FilterView: View {
    @Binding var criteria: LaunchCriteria
    @Environment(\.dismiss) var dismiss

    // Optimized: Using an optional LaunchStatus with a default value of nil
    // to represent "Any" status.
    @State private var selectedStatus: LaunchStatus? = nil
    @State private var selectedProvider: String = ""
    @State private var selectedRocketName: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var filterLocation: String = ""
    
    // Optimization: Dynamically generate the status options.
    // Ensure that LaunchStatus conforms to CaseIterable.
    private var statusOptions: [LaunchStatus?] {
        // The nil option represents "Any" status.
        [nil] + LaunchStatus.allCases
    }

    var body: some View {
        Form {
            Picker("Status", selection: $selectedStatus) {
                ForEach(statusOptions, id: \.self) { status in
                    if let status = status {
                        Text(status.displayText)
                            .tag(status as LaunchStatus?)
                    } else {
                        Text("Any")
                            .tag(nil as LaunchStatus?)
                    }
                }
            }
            
            TextField("Provider", text: $selectedProvider)
            TextField("Rocket Name", text: $selectedRocketName)
            
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            
            TextField("Location", text: $filterLocation)
        }
        .navigationTitle("Filter Launches")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Apply") {
                    applyFilters()
                }
            }
        }
    }
    
    private func applyFilters() {
        // Optimization: Ensure the date range is in the proper order.
        let dateRange: ClosedRange<Date> = startDate <= endDate ? startDate...endDate : endDate...startDate
        
        criteria = LaunchCriteria(
            status: selectedStatus,
            provider: selectedProvider.isEmpty ? nil : selectedProvider,
            rocketName: selectedRocketName.isEmpty ? nil : selectedRocketName,
            launchDateRange: dateRange,
            location: filterLocation.isEmpty ? nil : filterLocation
        )
        dismiss()
    }
}
