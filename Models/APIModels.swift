// Models/APIModels.swift

import Foundation

// MARK: - SpaceDevs API Response
struct SpaceDevsResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [SpaceDevsLaunch]
}

// MARK: - Launch Status
struct APILaunchStatus: Codable {
    let id: Int
    let name: String
    let abbrev: String
    let description: String
}

// MARK: - Launch Service Provider
struct LaunchServiceProvider: Codable {
    let id: Int
    let name: String
    let type: LaunchProviderType?
    
    enum LaunchProviderType: Codable {
        case government
        case commercial
        case unknown
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let typeDict = try? container.decode([String: String].self)
            let typeString = try? container.decode(String.self)
            
            switch typeString?.lowercased() ?? typeDict?["name"]?.lowercased() {
            case "government": self = .government
            case "commercial": self = .commercial
            default: self = .unknown
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .government: try container.encode("government")
            case .commercial: try container.encode("commercial")
            case .unknown: try container.encode("unknown")
            }
        }
    }
}

// MARK: - Rocket Configuration
struct RocketConfiguration: Codable {
    let id: Int
    let name: String
    let full_name: String
}

// MARK: - Rocket
struct Rocket: Codable {
    let id: Int
    let configuration: RocketConfiguration
}

// MARK: - Mission
struct Mission: Codable {
    let id: Int?
    let name: String?
    let description: String?
    let orbit: Orbit?
}

// MARK: - Orbit
struct Orbit: Codable {
    let id: Int
    let name: String
}

// MARK: - Location
struct Location: Codable {
    let id: Int
    let name: String
}

// MARK: - Pad
struct Pad: Codable {
    let id: Int
    let name: String
    let wiki_url: String?
    let location: Location
}

// MARK: - Image Info
struct ImageInfo: Codable {
    let id: Int
    let image_url: String
}

// MARK: - SpaceDevsLaunch
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
}

// MARK: - Launch Enrichment
struct LaunchEnrichment: Codable {
    let shortDescription: String?
    let detailedDescription: String?
    let status: LaunchStatus?
}
