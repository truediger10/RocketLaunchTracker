import Foundation
import SwiftUI

/**
 Represents a rocket launch, potentially enriched with extra descriptive information.
 
 This model consolidates launch metadata for easy display in the UI and handling in business logic.
 The `Launch` structure:
 - Conforms to `Identifiable` and `Codable` for easy integration with SwiftUI lists and JSON decoding.
 - Provides computed properties for user-friendly date formatting and launch state determination.
 - Includes an optional `badges` property to highlight special launches.
 */
struct Launch: Identifiable, Codable {
    // MARK: - Properties
    
    /// A unique identifier for the launch.
    let id: String
    /// The name of the launch (mission name or title).
    let name: String
    /// The scheduled date and time of the launch event.
    let launchDate: Date
    /// The status of the launch (e.g., upcoming, successful, failed).
    let status: LaunchStatus
    /// The rocket name or configuration used in the launch.
    let rocketName: String
    /// The organization or provider responsible for the launch.
    let provider: String
    /// The location or launch pad of the event.
    let location: String
    /// An optional URL to an image representing the launch, such as a mission patch or rocket photo.
    let imageURL: String?
    /// A brief overview or summary of the launch and mission.
    let shortDescription: String
    /// A more detailed description of the mission and its objectives.
    let detailedDescription: String
    /// An optional orbit designation if the mission targets a specific orbit.
    let orbit: String?
    /// An optional URL to a wiki page for additional information about the launch or pad.
    let wikiURL: String?
    /// An optional Twitter search URL for discovering related tweets or discussions.
    let twitterURL: String?
    /// An optional array of badges to highlight special launches like “Live,” “Exclusive,” “First Launch,” or “Notable.”
    let badges: [Badge]?

    // MARK: - Computed Properties
    
    /// Determines if the launch is scheduled for a future date.
    var isUpcoming: Bool {
        launchDate > Date()
    }
    
    /// Provides a nicely formatted, user-friendly string representation of the launch date.
    var formattedDate: String {
        launchDate.formatted(date: .long, time: .shortened)
    }
    
    /// Provides a user-friendly string indicating the time remaining until launch or if it has already launched.
    var timeUntilLaunch: String {
        let now = Date()
        
        // If the launch is in the future, return a countdown string.
        if launchDate > now {
            let interval = launchDate.timeIntervalSince(now)
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .short
            return formatter.string(from: interval) ?? "N/A until launch"
        } else {
            // If the launch date is in the past or present, indicate it's already launched.
            return "Launched"
        }
    }
}

/**
 An enumeration representing the status of a rocket launch.
 
 Cases correspond to distinct phases or outcomes of a launch event. The `displayText` property
 offers a human-readable variant suitable for UI labels, accessibility, and logging.
 */

