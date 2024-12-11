// Models/LaunchCriteria.swift

import Foundation

struct LaunchCriteria {
    var status: LaunchStatus?
    var provider: String?
    var rocketName: String?
    var launchDateRange: ClosedRange<Date>?
    var location: String?
    
    /// Determines if a launch matches the criteria.
    /// - Parameter launch: The launch to evaluate.
    /// - Returns: `true` if the launch matches all criteria, `false` otherwise.
    func matches(_ launch: Launch) -> Bool {
        // Check status
        if let status = status, launch.status != status {
            return false
        }
        
        // Check provider
        if let provider = provider, !provider.isEmpty,
           !launch.provider.localizedCaseInsensitiveContains(provider) {
            return false
        }
        
        // Check rocket name
        if let rocketName = rocketName, !rocketName.isEmpty,
           !launch.rocketName.localizedCaseInsensitiveContains(rocketName) {
            return false
        }
        
        // Check launch date range
        if let dateRange = launchDateRange {
            if let launchDate = launch.launchDate {
                if !dateRange.contains(launchDate) {
                    return false
                }
            } else {
                return false
            }
        }
        
        // Check location
        if let location = location, !location.isEmpty,
           !launch.location.localizedCaseInsensitiveContains(location) {
            return false
        }
        
        return true
    }
}
