import Foundation

// MARK: - SpaceDevs API Models
struct SpaceDevsResponse: Codable {
    let count: Int
    let next: String?
    let results: [SpaceDevsLaunch]
}

struct SpaceDevsLaunch: Codable {
    let id: String
    let name: String
    let net: String
    let status: LaunchStatus
    let launch_service_provider: LaunchServiceProvider
    let rocket: Rocket
    let mission: Mission?
    let pad: Pad
    let image: ImageInfo?
    
    struct LaunchStatus: Codable {
        let id: Int
        let name: String
        let abbrev: String
        let description: String
    }
    
    struct LaunchServiceProvider: Codable {
        let id: Int
        let name: String
        let type: ProviderType?
        
        struct ProviderType: Codable {
            let id: Int
            let name: String
        }
    }
    
    struct Rocket: Codable {
        let configuration: RocketConfiguration
        
        struct RocketConfiguration: Codable {
            let name: String
            let full_name: String
        }
    }
    
    struct Mission: Codable {
        let name: String
        let description: String?
        let type: String
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

// Function to convert API launch to app Launch model
extension SpaceDevsLaunch {
    func toAppLaunch() -> Launch {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        return Launch(
            id: id,
            name: name,
            launchDate: dateFormatter.date(from: net) ?? Date(),
            status: .init(rawValue: status.name) ?? .upcoming,
            rocketName: rocket.configuration.full_name,
            provider: launch_service_provider.name,
            location: pad.location.name,
            imageURL: image?.image_url,
            shortDescription: mission?.description ?? "No description available",
            detailedDescription: mission?.description ?? "No detailed description available",
            orbit: mission?.orbit?.name,
            wikiURL: pad.wiki_url
        )
    }
}