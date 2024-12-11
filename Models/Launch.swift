// Models/Launch.swift

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
    let shortDescription: String?
    let detailedDescription: String?
    let orbit: String?
    let wikiURL: String?
    let twitterURL: String?
    let badges: [Badge]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, location
        case launchDate = "net"
        case rocketName = "rocket"
        case provider = "launch_service_provider"
        case imageURL = "image"
        case shortDescription = "mission_description"
        case detailedDescription = "detailed_description"
        case orbit = "orbit_name"
        case wikiURL = "wiki_url"
        case twitterURL = "twitter_url"
        case badges
    }
    
    var isUpcoming: Bool { launchDate > Date() }
    var formattedDate: String { launchDate.formatted(date: .long, time: .shortened) }
    
    var timeUntilLaunch: String {
        let now = Date()
        if launchDate > now {
            let interval = launchDate.timeIntervalSince(now)
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .short
            return formatter.string(from: interval) ?? "N/A until launch"
        }
        return "Launched"
    }
}
