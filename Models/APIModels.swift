import Foundation

// MARK: - SpaceDevs API Response

/**
 Represents the top-level response from the SpaceDevs API containing multiple launches.

 - Parameters:
    - count: The total number of launches available.
    - next: A URL string for the next page of results, if any.
    - results: An array of `SpaceDevsLaunch` objects representing individual launches.
 */
struct SpaceDevsResponse: Codable {
    let count: Int
    let next: String?
    let results: [SpaceDevsLaunch]
}

// MARK: - Launch and Related Models

/**
 Represents a single launch as returned by the SpaceDevs API.

 Each `SpaceDevsLaunch` maps closely to the API’s JSON structure. Use `toAppLaunch(withEnrichment:)`
 to convert this into the app’s internal `Launch` model.
 */
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
    
    /// Represents the status of a launch, including its name, abbreviation, and a description.
    struct APILaunchStatus: Codable {
        let id: Int
        let name: String
        let abbrev: String
        let description: String
    }
    
    /// The provider organization responsible for the launch.
    struct LaunchServiceProvider: Codable {
        let id: Int
        let name: String
    }
    
    /// The rocket used in the launch, with configuration details.
    struct Rocket: Codable {
        let configuration: RocketConfiguration
        
        struct RocketConfiguration: Codable {
            let name: String
            let full_name: String
        }
    }
    
    /// Mission details, including its name, description, type, and target orbit.
    struct Mission: Codable {
        let name: String?
        let description: String?
        let type: String?
        let orbit: Orbit?
        
        struct Orbit: Codable {
            let name: String
        }
    }
    
    /// Information about the launch pad, including its location and an optional wiki URL.
    struct Pad: Codable {
        let name: String
        let wiki_url: String?
        let location: Location
        
        struct Location: Codable {
            let name: String
        }
    }
    
    /// Information about images associated with the launch.
    struct ImageInfo: Codable {
        let image_url: String?
    }
}

// MARK: - Launch Enrichment

/**
 Represents additional enrichment data for a launch, such as enhanced short and detailed descriptions.
 This data might be fetched from a cache or enrichment service and merged into the final `Launch` model.
 */
struct LaunchEnrichment: Codable {
    let shortDescription: String
    let detailedDescription: String
}

// MARK: - Converting SpaceDevsLaunch to App Launch

extension SpaceDevsLaunch {
    
    /**
     Converts a `SpaceDevsLaunch` into the app’s internal `Launch` model.

     - Parameter enrichment: Optional `LaunchEnrichment` providing additional descriptive data.
     - Returns: A `Launch` model suitable for use throughout the app.
     
     This function:
     - Parses the ISO8601 `net` string into a `Date`.
     - Maps the API launch status to the app’s `LaunchStatus` enum.
     - Defaults descriptions if none are provided by either `mission` or `enrichment`.
     - Constructs a basic Twitter URL query for the launch.
     */
    func toAppLaunch(withEnrichment enrichment: LaunchEnrichment? = nil) -> Launch {
        // Parse the ISO8601 date string, defaulting to current Date if parsing fails.
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let launchDate = dateFormatter.date(from: net) ?? Date()
        
        // Map the API’s status name to the app’s `LaunchStatus` enum.
        let mappedStatus: LaunchStatus = {
            switch status.name.lowercased() {
            case "go for launch": return .upcoming
            case "in flight": return .launching
            case "launch successful": return .successful
            case "launch failure": return .failed
            case "launch delayed": return .delayed
            case "launch cancelled": return .cancelled
            default: return .upcoming
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
            wikiURL: pad.wiki_url,
            twitterURL: buildTwitterURL()
        )
    }
    
    /// Constructs a Twitter search URL based on the launch name.
    /// This can be used to quickly find related tweets about the launch.
    private func buildTwitterURL() -> String? {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return "https://twitter.com/search?q=\(encodedName)"
    }
}
