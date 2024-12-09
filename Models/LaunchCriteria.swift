import Foundation

/**
 A set of criteria used to filter launches based on date ranges, status, and location.
 
 `LaunchCriteria` is used to determine if a given `Launch` meets specified conditions.
 This can be utilized in search or filtering features, allowing users to narrow down
 launches of interest by customizing these criteria.
 
 - Properties:
   - startDate: Optional earliest launch date. Launches before this date are excluded.
   - endDate: Optional latest launch date. Launches after this date are excluded.
   - status: Optional required status (e.g., Upcoming, Successful). Launches not matching this status are excluded.
   - location: Optional substring to match against the launch location. Launches whose location does not contain this string are excluded.
 */
struct LaunchCriteria {
    /// The earliest acceptable launch date. Launches before this date will not match.
    var startDate: Date?
    /// The latest acceptable launch date. Launches after this date will not match.
    var endDate: Date?
    /// The required launch status. If set, launches must match this status to be included.
    var status: LaunchStatus?
    /// A substring to search for in the launch location. Launches whose location does not contain this substring are excluded.
    var location: String?
    
    /**
     Determines if a given `Launch` object matches all criteria specified in this structure.
     
     The `matches(_:)` method:
     - Checks if the launch date falls within the optional start and end dates.
     - Verifies that the launch status matches the required status if specified.
     - Ensures that the launch location contains the specified substring if provided.
     
     - Parameter launch: The `Launch` object to be tested against the criteria.
     - Returns: `true` if the launch meets all criteria; otherwise, `false`.
     */
    func matches(_ launch: Launch) -> Bool {
        // Check the date range if specified.
        if let start = startDate, launch.launchDate < start {
            return false
        }
        if let end = endDate, launch.launchDate > end {
            return false
        }
        
        // Check if the launch status matches the required status (if specified).
        if let requiredStatus = status, launch.status != requiredStatus {
            return false
        }
        
        // Check if the launch location contains the required substring (case-insensitive).
        if let requiredLocation = location,
           !launch.location.localizedCaseInsensitiveContains(requiredLocation) {
            return false
        }
        
        // If all checks pass, the launch matches the criteria.
        return true
    }
}
