// Models/Launch.swift

import Foundation

struct Launch: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let net: Date?
    var status: LaunchStatus
    let rocket: String
    let provider: String
    let location: String
    let imageURL: String?
    var shortDescription: String?    // Changed to var
    var detailedDescription: String? // Changed to var
    let orbit: String?
    let wikiURL: String?
    let twitterURL: String?
    let badges: [Badge]?
    
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
    
    var rocketName: String {
        rocket
    }
    
    var launchDate: Date? {
        net
    }
}

// Extension to map SpaceDevsLaunch to Launch
extension SpaceDevsLaunch {
    /// Maps the API model to your app’s Launch model.
    /// Returns nil if the launch date is not in the future.
    func toAppLaunch(withEnrichment enrichment: LaunchEnrichment? = nil) -> Launch? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        guard let launchDate = dateFormatter.date(from: net),
              launchDate > Date() else {
            // Exclude non-upcoming launches for now.
            return nil
        }
        
        // For now, all future launches are marked as upcoming.
        let mappedStatus: LaunchStatus = .upcoming
        
        // Determine additional badges (e.g., notable) using your criteria.
        let badges = determineBadges()
        
        return Launch(
            id: id,
            name: name,
            net: launchDate,
            status: mappedStatus,
            rocket: rocket.configuration.full_name,
            provider: launch_service_provider.name,
            location: pad.location.name,
            imageURL: image?.image_url,
            shortDescription: enrichment?.shortDescription ?? mission?.description ?? "No description available",
            detailedDescription: enrichment?.detailedDescription ?? mission?.description ?? "No detailed description available",
            orbit: mission?.orbit?.name,
            wikiURL: pad.wiki_url,
            twitterURL: buildTwitterURL(),
            badges: badges.isEmpty ? nil : badges
        )
    }
    
    private func determineBadges() -> [Badge] {
        var badges: [Badge] = []
        
        // For notable launches, check mission description and provider.
        if let missionDescription = mission?.description?.lowercased() {
            if missionDescription.contains("maiden") || missionDescription.contains("first") {
                badges.append(.firstLaunch)
            }
            if missionDescription.contains("national security")
                || missionDescription.contains("historic")
                || missionDescription.contains("key mission")
                || missionDescription.contains("flagship")
                || missionDescription.contains("first in class")
            {
                badges.append(.notable)
            }
        }
        
        // Mark high-profile provider launches as notable.
        let providerName = launch_service_provider.name.lowercased()
        if providerName.contains("nasa") || providerName.contains("spacex") {
            if !badges.contains(.notable) {
                badges.append(.notable)
            }
        }
        
        return badges
    }
    
    private func buildTwitterURL() -> String? {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return "https://twitter.com/search?q=\(encodedName)"
    }
}
