import Foundation

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
        launchDate > Date() && status != .cancelled
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
}
