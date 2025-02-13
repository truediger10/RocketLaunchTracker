//
//  APIModels.swift
//  RocketLaunchTracker
//

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
            if let typeString = try? container.decode(String.self) {
                switch typeString.lowercased() {
                case "government": self = .government
                case "commercial": self = .commercial
                default: self = .unknown
                }
            } else if let typeDict = try? container.decode([String: String].self),
                      let nameValue = typeDict["name"]?.lowercased() {
                switch nameValue {
                case "government": self = .government
                case "commercial": self = .commercial
                default: self = .unknown
                }
            } else {
                self = .unknown
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .government:
                try container.encode("government")
            case .commercial:
                try container.encode("commercial")
            case .unknown:
                try container.encode("unknown")
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

/// Represents a single launch from SpaceDevs (in “list” mode).
struct SpaceDevsLaunch: Codable {
    // Basic fields
    let id: String
    let name: String
    let net: String

    // Possibly-nested objects
    let status: APILaunchStatus?
    let launch_service_provider: LaunchServiceProvider?
    let rocket: Rocket?
    let mission: Mission?
    let pad: Pad?

    // If “image” might be an object or a simple string
    let imageObject: ImageInfo?
    let imageString: String?

    // Flattened fields in list mode
    let status_name: String?
    let rocket_name: String?
    let agency_name: String?
    let pad_name: String?

    enum CodingKeys: String, CodingKey {
        case id, name, net
        case status
        case launch_service_provider
        case rocket
        case mission
        case pad
        case image  // can be object or string
        case status_name, rocket_name, agency_name, pad_name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        net = try container.decode(String.self, forKey: .net)

        // Nested objects
        status = try? container.decode(APILaunchStatus.self, forKey: .status)
        launch_service_provider = try? container.decode(LaunchServiceProvider.self, forKey: .launch_service_provider)
        rocket = try? container.decode(Rocket.self, forKey: .rocket)
        mission = try? container.decode(Mission.self, forKey: .mission)
        pad = try? container.decode(Pad.self, forKey: .pad)

        // Attempt to decode “image” as an object, else fallback to string
        if let imageObj = try? container.decode(ImageInfo.self, forKey: .image) {
            imageObject = imageObj
            imageString = nil
        } else {
            imageObject = nil
            imageString = try? container.decode(String.self, forKey: .image)
        }

        // Flattened fields
        status_name = try? container.decode(String.self, forKey: .status_name)
        rocket_name = try? container.decode(String.self, forKey: .rocket_name)
        agency_name = try? container.decode(String.self, forKey: .agency_name)
        pad_name = try? container.decode(String.self, forKey: .pad_name)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(net, forKey: .net)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(launch_service_provider, forKey: .launch_service_provider)
        try container.encodeIfPresent(rocket, forKey: .rocket)
        try container.encodeIfPresent(mission, forKey: .mission)
        try container.encodeIfPresent(pad, forKey: .pad)

        if let imageObj = imageObject {
            try container.encode(imageObj, forKey: .image)
        } else if let imageStr = imageString {
            try container.encode(imageStr, forKey: .image)
        }
        
        try container.encodeIfPresent(status_name, forKey: .status_name)
        try container.encodeIfPresent(rocket_name, forKey: .rocket_name)
        try container.encodeIfPresent(agency_name, forKey: .agency_name)
        try container.encodeIfPresent(pad_name, forKey: .pad_name)
    }
}

// MARK: - Launch Enrichment
struct LaunchEnrichment: Codable {
    let shortDescription: String?
    let detailedDescription: String?
    let status: LaunchStatus?
}
