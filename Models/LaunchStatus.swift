import Foundation

enum LaunchStatus: String, Codable, CaseIterable {
    case go = "Go"
    case tbd = "To Be Determined"
    case success = "Success"
    case failure = "Failure"
    case hold = "Hold"
    case inFlight = "In Flight"
    case partialFailure = "Partial Failure"
    case other = "Other"

    init(statusName: String) {
        self = LaunchStatus(rawValue: statusName) ?? .other
    }
}
