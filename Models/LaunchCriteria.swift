import Foundation

struct LaunchCriteria {
    var startDate: Date?
    var endDate: Date?
    var status: LaunchStatus?
    var location: String?
    
    func matches(_ launch: Launch) -> Bool {
        // Check date range
        if let start = startDate, launch.launchDate < start {
            return false
        }
        if let end = endDate, launch.launchDate > end {
            return false
        }
        
        // Check status
        if let requiredStatus = status, launch.status != requiredStatus {
            return false
        }
        
        // Check location
        if let requiredLocation = location, !launch.location.localizedCaseInsensitiveContains(requiredLocation) {
            return false
        }
        
        return true
    }
}
