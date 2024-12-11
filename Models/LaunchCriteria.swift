// Models/LaunchCriteria.swift

import Foundation

/**
 Represents the criteria used to filter launches.
 */
struct LaunchCriteria: Codable {
    var status: LaunchStatus?
    var provider: String?
    var rocketName: String?
    var launchDateRange: ClosedRange<Date>?
    var location: String?
    // Add more criteria as needed
    
    /**
     Determines if a given launch matches the criteria.
     
     - Parameter launch: The `Launch` object to evaluate.
     - Returns: `true` if the launch matches all non-nil criteria; otherwise, `false`.
     */
    func matches(_ launch: Launch) -> Bool {
        let conditions: [Bool] = [
            status.map { $0 == launch.status } ?? true,
            provider.map { launch.provider.lowercased().contains($0.lowercased()) } ?? true,
            rocketName.map { launch.rocketName.lowercased().contains($0.lowercased()) } ?? true,
            launchDateRange.map { $0.contains(launch.launchDate) } ?? true,
            location.map { launch.location.lowercased().contains($0.lowercased()) } ?? true
        ]
        return conditions.allSatisfy { $0 }
    }
}
