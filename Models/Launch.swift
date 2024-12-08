import Foundation

/// Represents a rocket launch, enriched with descriptive info from the OpenAI API.
struct Launch: Identifiable, Codable {
    let id: String
    let name: String
    let launchDate: Date
    let status: LaunchStatus
    let rocketName: String
    let provider: String
    let location: String
    let imageURL: String?
    let shortDescription: String
    let detailedDescription: String
    let orbit: String?
    let wikiURL: String?
    
    var isUpcoming: Bool {
        launchDate > Date()
    }
    
    var formattedDate: String {
        launchDate.formatted(date: .long, time: .shortened)
    }
}

enum LaunchStatus: String, Codable {
    case upcoming = "Go for Launch"
    case launching = "In Flight"
    case successful = "Launch Successful"
    case failed = "Launch Failure"
    case delayed = "Launch Delayed"
    case cancelled = "Launch Cancelled"
    
    var displayText: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .launching: return "Launching"
        case .successful: return "Successful"
        case .failed: return "Failed"
        case .delayed: return "Delayed"
        case .cancelled: return "Cancelled"
        }
    }
}

extension Launch {
    var timeUntilLaunch: String {
        let now = Date()
        if launchDate > now {
            let diff = launchDate.timeIntervalSince(now)
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .short
            if let formatted = formatter.string(from: diff) {
                return "\(formatted) until launch"
            } else {
                return "N/A until launch"
            }
        } else {
            return "Launched"
        }
    }
}
