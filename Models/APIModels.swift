import Foundation

// MARK: - SpaceDevs API Response
struct SpaceDevsResponse: Codable {
    let count: Int
    let next: String?
    let results: [SpaceDevsLaunch]
}

// MARK: - Launch and Related Models
struct SpaceDevsLaunch: Codable {
    let id: String
    let name: String
    let net: String
    let status: APILaunchStatus
    let launch_service_provider: LaunchServiceProvider
    let rocket: Rocket
    let mission: Mission?
    let pad: Pad
    let image: ImageInfo?
    
    struct APILaunchStatus: Codable {
        let id: Int
        let name: String
        let abbrev: String
        let description: String
    }
    
    struct LaunchServiceProvider: Codable {
        let id: Int
        let name: String
    }
    
    struct Rocket: Codable {
        let configuration: RocketConfiguration
        struct RocketConfiguration: Codable {
            let name: String
            let full_name: String
        }
    }
    
    struct Mission: Codable {
        let name: String?
        let description: String?
        let type: String?
        let orbit: Orbit?
        
        struct Orbit: Codable {
            let name: String
        }
    }
    
    struct Pad: Codable {
        let name: String
        let wiki_url: String?
        let location: Location
        
        struct Location: Codable {
            let name: String
        }
    }
    
    struct ImageInfo: Codable {
        let image_url: String?
    }
}

// MARK: - Launch Enrichment
struct LaunchEnrichment: Codable {
    let shortDescription: String
    let detailedDescription: String
}

// MARK: - Converting SpaceDevsLaunch to App Launch
extension SpaceDevsLaunch {
    func toAppLaunch(withEnrichment enrichment: LaunchEnrichment? = nil) -> Launch {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let launchDate = dateFormatter.date(from: net) ?? Date()
        
        // Map the API status name to the LaunchStatus enum used by the app's Launch model.
        let mappedStatus: LaunchStatus = {
            switch status.name.lowercased() {
            case "go for launch":
                return .upcoming
            case "in flight":
                return .launching
            case "launch successful":
                return .successful
            case "launch failure":
                return .failed
            case "launch delayed":
                return .delayed
            case "launch cancelled":
                return .cancelled
            default:
                return .upcoming
            }
        }()
        
        return Launch(
            id: id,
            name: name,
            launchDate: launchDate,
            status: mappedStatus,
            rocketName: rocket.configuration.full_name,
            provider: launch_service_provider.name,
            location: pad.location.name,
            imageURL: image?.image_url,
            shortDescription: enrichment?.shortDescription ?? mission?.description ?? "No description available",
            detailedDescription: enrichment?.detailedDescription ?? mission?.description ?? "No detailed description available",
            orbit: mission?.orbit?.name,
            wikiURL: pad.wiki_url
        )
    }
}
