//
//  APIModels.swift
//  RocketLaunchTracker
//
//  Decodes data from The Space Devs Launch Library 2 API
//  and maps them to your local Launch model if needed.
//
import Foundation

// MARK: - API Response
struct SpaceDevsResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [SpaceDevsLaunch]
}

// MARK: - SpaceDevsLaunch Model
struct SpaceDevsLaunch: Codable {
    let id: String
    let name: String
    let net: String  // The API returns an ISO8601 date string for the planned launch time.
    
    let status: LaunchStatusWrapper
    let image: ImageWrapper?
    let rocket: RocketWrapper?
    let launch_service_provider: ProviderWrapper?
    let pad: PadWrapper?
    let mission: MissionWrapper?
    let orbit: OrbitWrapper?
}

// Example sub-wrappers:
struct LaunchStatusWrapper: Codable {
    let name: String
    let abbrev: String?
}

struct ImageWrapper: Codable {
    let image_url: String
}

struct RocketWrapper: Codable {
    let configuration: RocketConfiguration
}

struct RocketConfiguration: Codable {
    let full_name: String
}

struct ProviderWrapper: Codable {
    let name: String
}

struct PadWrapper: Codable {
    let location: PadLocationWrapper
    let wiki_url: String?
}

struct PadLocationWrapper: Codable {
    let name: String
}

struct MissionWrapper: Codable {
    let description: String
    let orbit: OrbitWrapper?
}

struct OrbitWrapper: Codable {
    let name: String
}

// MARK: - Launch Enrichment
/// If you want to store AI-generated text
struct LaunchEnrichment: Codable {
    let shortDescription: String
    let detailedDescription: String
}

// MARK: - SpaceDevsLaunch → Launch Conversion
extension SpaceDevsLaunch {
    /// Maps the API model to your app’s Launch model.
    /// Returns nil if the launch date is in the past or can't be parsed.
    func toAppLaunch(withEnrichment enrichment: LaunchEnrichment? = nil) -> Launch? {
        // Parse date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        guard let launchDate = dateFormatter.date(from: net),
              launchDate > Date() else {
            return nil
        }
        
        // Hard-coded status for example. Or parse `status.name`
        let mappedStatus: LaunchStatus = .upcoming
        
        // Build local fields
        let rocketName = rocket?.configuration.full_name ?? "N/A"
        
        // Extract only the mission name:
        let missionName: String = {
            let components = name.split(separator: "|")
            if components.count >= 2 {
                return components[1].trimmingCharacters(in: .whitespaces)
            } else {
                return name
            }
        }()
        
        let providerName: String = {
            if let prov = launch_service_provider?.name, !prov.isEmpty {
                return prov
            } else {
                return missionName
            }
        }()
        
        let location = pad?.location.name ?? "N/A"
        
        // If you have an existing mission description from the API
        let missionDesc = mission?.description
        
        // Merge with optional enrichment if present
        let shortDesc = enrichment?.shortDescription ?? missionDesc ?? "No description available"
        let detailedDesc = enrichment?.detailedDescription ?? missionDesc ?? "No detailed description available"
        
        let orbitName = mission?.orbit?.name
        
        // Build a local Launch object using missionName instead of the full name
        return Launch(
            id: id,
            name: missionName,  // Only the mission name is displayed
            net: launchDate,
            status: mappedStatus,
            rocket: rocketName,
            provider: providerName,
            location: location,
            imageURL: image?.image_url,
            shortDescription: shortDesc,
            detailedDescription: detailedDesc,
            orbit: orbitName,
            wikiURL: pad?.wiki_url,
            twitterURL: buildTwitterURL(),
            badges: determineBadges()
        )
    }
    
    private func determineBadges() -> [Badge]? {
        var badges: [Badge] = []
        
        if let desc = mission?.description.lowercased() {
            if desc.contains("maiden") || desc.contains("first") {
                badges.append(.firstLaunch)
            }
            if desc.contains("historic") || desc.contains("notable") {
                badges.append(.notable)
            }
        }
        
        if let provider = launch_service_provider?.name.lowercased() {
            if provider.contains("nasa") || provider.contains("spacex") || provider.contains("blue origin") {
                if !badges.contains(.notable) {
                    badges.append(.notable)
                }
            }
        }
        
        if let rocketName = rocket?.configuration.full_name.lowercased() {
            if rocketName.contains("starship") {
                if !badges.contains(.notable) {
                    badges.append(.notable)
                }
            }
        }
        
        return badges.isEmpty ? nil : badges
    }
    
    private func buildTwitterURL() -> String? {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return "https://twitter.com/search?q=\(encodedName)"
    }
}
