// Views/LaunchList/FilterView.swift

import SwiftUI

struct FilterView: View {
    @Binding var criteria: LaunchCriteria
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedStatus: LaunchStatus?
    @State private var selectedProvider: String = ""
    @State private var selectedRocketName: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var filterLocation: String = ""
    
    var body: some View {
        Form {
            Picker("Status", selection: $selectedStatus) {
                Text("Any").tag(nil as LaunchStatus?)
                Text("Upcoming").tag(LaunchStatus.upcoming as LaunchStatus?)
                Text("Launching").tag(LaunchStatus.launching as LaunchStatus?)
                Text("Successful").tag(LaunchStatus.successful as LaunchStatus?)
                Text("Failed").tag(LaunchStatus.failed as LaunchStatus?)
                Text("Delayed").tag(LaunchStatus.delayed as LaunchStatus?)
                Text("Cancelled").tag(LaunchStatus.cancelled as LaunchStatus?)
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
        // Ensure that startDate is before endDate
        let dateRange = startDate <= endDate ? startDate...endDate : endDate...startDate
        
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
