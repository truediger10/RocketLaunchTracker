// Models/Launch.swift

import Foundation

struct Launch: Identifiable, Codable {
    let id: String
    let name: String
    let net: Date? // Changed from 'launchDate' to 'net'
    let status: LaunchStatus
    let rocket: Rocket
    let provider: String
    let location: String
    let imageURL: String?
    let shortDescription: String?
    let detailedDescription: String?
    let orbit: String?
    let wikiURL: String?
    let twitterURL: String?
    let badges: [Badge]?
    
    // Custom CodingKeys to map 'net' to 'launchDate'
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case net
        case status
        case rocket
        case provider
        case location
        case imageURL
        case shortDescription
        case detailedDescription
        case orbit
        case wikiURL
        case twitterURL
        case badges
    }
    
    var formattedDate: String {
        guard let date = net else { return "Date not available" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var timeUntilLaunch: String {
        guard let date = net else { return "Launch date not available" }
        let now = Date()
        let interval = date.timeIntervalSince(now)
        if interval < 0 {
            return "Launched"
        }
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(days)d \(hours)h \(minutes)m"
    }
    
    /// Computed property for rocket name.
    var rocketName: String {
        rocket.configuration.name
    }
    
    /// Computed property for launch date.
    var launchDate: Date? {
        net
    }
}

struct Rocket: Codable {
    let id: String
    let configuration: RocketConfiguration
}

struct RocketConfiguration: Codable {
    let id: String
    let name: String
    let family: String
    let fullName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case family
        case fullName = "full_name"
    }
}
