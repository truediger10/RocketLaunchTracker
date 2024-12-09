// Views/LaunchList/FilterView.swift
import SwiftUI

struct FilterView: View {
    @Binding var criteria: LaunchCriteria
    @Environment(\.dismiss) var dismiss
    
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
                        Text("Any").tag(Optional<LaunchStatus>.none)
                        Text("Upcoming").tag(Optional(LaunchStatus.upcoming))
                        Text("Launching").tag(Optional(LaunchStatus.launching))
                        Text("Successful").tag(Optional(LaunchStatus.successful))
                        Text("Failed").tag(Optional(LaunchStatus.failed))
                        Text("Delayed").tag(Optional(LaunchStatus.delayed))
                        Text("Cancelled").tag(Optional(LaunchStatus.cancelled))
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
