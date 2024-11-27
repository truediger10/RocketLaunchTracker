import Foundation

// MARK: - SpaceDevsResponse

struct SpaceDevsResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [SpaceDevsLaunch]
}

// MARK: - SpaceDevsLaunch

struct SpaceDevsLaunch: Codable {
    let id: String
    let name: String
    let net: String
    let status: Status
    let rocket: Rocket
    let mission: Mission?
    let pad: Pad
    let image: String?
    let webcastLive: Bool?
    let infoURLs: [String]?
    let vidURLs: [String]?
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, net, status, rocket, mission, pad, image
        case webcastLive = "webcast_live"
        case infoURLs = "infoURLs"
        case vidURLs = "vidURLs"
        case imageURL = "image_url"
    }
}

// MARK: - Status

struct Status: Codable {
    let id: Int
    let name: String
}

// MARK: - Rocket

struct Rocket: Codable {
    let configuration: Configuration
}

// MARK: - Configuration

struct Configuration: Codable {
    let name: String
}

// MARK: - Mission

struct Mission: Codable {
    let description: String?
    let type: String?
    let orbit: Orbit?
}

// MARK: - Orbit

struct Orbit: Codable {
    let name: String?
}

// MARK: - Pad

struct Pad: Codable {
    let name: String
    let location: PadLocation
}

// MARK: - PadLocation

struct PadLocation: Codable {
    let name: String
    let countryCode: String?

    enum CodingKeys: String, CodingKey {
        case name
        case countryCode = "country_code"
    }
}
