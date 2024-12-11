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
    func toAppLaunch(withEnrichment enrichment: LaunchEnrichment? = nil) -> Launch {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let launchDate = dateFormatter.date(from: net) ?? Date()
        
        let mappedStatus: LaunchStatus = {
            switch status.name.lowercased() {
            case "go for launch": return .upcoming
            case "in flight": return .launching
            case "launch successful": return .successful
            case "launch failure": return .failed
            case "launch delayed": return .delayed
            case "launch cancelled": return .cancelled
            default: return .unknown
            }
        }()
        
        let badges = determineBadges(mappedStatus: mappedStatus)
        
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
    
    private func determineBadges(mappedStatus: LaunchStatus) -> [Badge] {
        var badges: [Badge] = []
        
        if mappedStatus == .launching {
            badges.append(.live)
        }
        
        if self.rocket.configuration.name.lowercased().contains("exclusive") {
            badges.append(.exclusive)
        }
        
        if let missionDescription = mission?.description?.lowercased(),
           missionDescription.contains("maiden") || missionDescription.contains("first") {
            badges.append(.firstLaunch)
        }
        
        if let missionDescription = mission?.description?.lowercased(),
           missionDescription.contains("national security") {
            badges.append(.notable)
        }
        
        return badges
    }
    
    private func buildTwitterURL() -> String? {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return "https://twitter.com/search?q=\(encodedName)"
    }
}
