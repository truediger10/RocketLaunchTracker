//
//  Launch.swift
//  RocketLaunchTracker
//

import Foundation
import SwiftUI

/// Your main Launch structure, referencing the single enum-based LaunchStatus and Badge from LaunchEnums.swift
struct Launch: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let net: Date?
    
    var status: LaunchStatus
    let rocket: String
    let provider: String
    let location: String
    let imageURL: String?
    
    var shortDescription: String?
    var detailedDescription: String?
    let orbit: String?
    let wikiURL: String?
    let twitterURL: String?
    let badges: [Badge]?
    
    // MARK: - Date Formatting
    var formattedDate: String {
        guard let date = net else { return "Date not available" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Time Until Launch
    var timeUntilLaunch: String {
        guard let date = net else { return "Launch date not available" }
        let interval = date.timeIntervalSinceNow
        if interval < 0 { return "Launched" }
        
        let days = Int(interval / 86400)
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(days)d \(hours)h \(minutes)m"
    }
    
    // MARK: - Convenience
    var rocketName: String { rocket }
    var launchDate: Date? { net }
}
