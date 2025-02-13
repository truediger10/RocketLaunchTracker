//
//  Launch.swift
//  RocketLaunchTracker
//

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
    var shortDescription: String?    // Updated after enrichment
    var detailedDescription: String? // Updated after enrichment
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
        let interval = date.timeIntervalSince(Date())
        if interval < 0 { return "Launched" }
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(days)d \(hours)h \(minutes)m"
    }

    var rocketName: String { rocket }
    var launchDate: Date? { net }
}

// MARK: - Conversion from API Model to App Model

extension SpaceDevsLaunch {
    func toAppLaunch(withEnrichment enrichment: LaunchEnrichment? = nil) -> Launch {
        // Convert net (String) to Date
        let dateFormatter = ISO8601DateFormatter()
        let launchDate = dateFormatter.date(from: net)
        
        // Determine launch status from either the detailed status object or the flattened status_name
        let statusString = status?.name ?? status_name ?? "unknown"
        let mappedStatus: LaunchStatus = {
            switch statusString.lowercased() {
            case "go for launch":       return .upcoming
            case "in flight":          return .launching
            case "launch successful":  return .successful
            case "launch failure":     return .failed
            case "launch delayed":     return .delayed
            case "launch cancelled":   return .cancelled
            default:                   return .unknown
            }
        }()
        
        // Use rocket configuration's full_name if available, else the flattened rocket_name, else fallback
        let rocketName = rocket?.configuration.full_name ?? rocket_name ?? "Unknown Rocket"
        
        // Use the provider object’s name if available, else the flattened agency_name
        let providerName = launch_service_provider?.name ?? agency_name ?? "Unknown Provider"
        
        // Pad location name from nested pad object or the flattened pad_name
        let locationName = pad?.location.name ?? pad_name ?? "Unknown Location"
        
        // Image URL from either imageObject or imageString
        let imageUrl = imageObject?.image_url ?? imageString
        
        // If we have no GPT enrichment, default to mission.description
        let defaultDesc = mission?.description ?? "No description available"
        let shortDesc = enrichment?.shortDescription ?? defaultDesc
        let detailedDesc = enrichment?.detailedDescription ?? defaultDesc
        
        // Orbit name if available
        let orbitName = mission?.orbit?.name
        
        // Construct a Twitter search URL for the launch name
        let twitterURL: String? = {
            guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return "https://twitter.com/search?q=\(encoded)"
        }()
        
        // Simple badge logic (customize as needed)
        var badgeList: [Badge] = []
        if mappedStatus == .launching {
            badgeList.append(.live)
        }
        if let rocketObj = rocket,
           rocketObj.configuration.name.lowercased().contains("exclusive") {
            badgeList.append(.exclusive)
        }
        if let missionDesc = mission?.description?.lowercased() {
            if missionDesc.contains("maiden") || missionDesc.contains("first") {
                badgeList.append(.firstLaunch)
            }
            if missionDesc.contains("national security") {
                badgeList.append(.notable)
            }
        }
        
        return Launch(
            id: id,
            name: name,
            net: launchDate,
            status: enrichment?.status ?? mappedStatus,
            rocket: rocketName,
            provider: providerName,
            location: locationName,
            imageURL: imageUrl,
            shortDescription: shortDesc,
            detailedDescription: detailedDesc,
            orbit: orbitName,
            wikiURL: pad?.wiki_url,
            twitterURL: twitterURL,
            badges: badgeList.isEmpty ? nil : badgeList
        )
    }
}
