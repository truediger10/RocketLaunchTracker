import Foundation

struct Launch: Identifiable, Codable {
    let id: String
    let name: String
    let launchDate: String?
    let status: LaunchStatus
    let rocketName: String
    let provider: String
    let location: String
    let imageURL: String?
    let shortDescription: String?
    let detailedDescription: String?
    let wikiURL: String?
    let missionType: String?
    let orbit: String?
    let providerStats: ProviderStats?
    let padInfo: PadInfo?
    let windowStart: String?
    let windowEnd: String?
    let probability: Int?
    let weatherConcerns: String?
    let videoURLs: [String]?
    let infoURLs: [String]?
    let imageCredit: String?
}

struct PadInfo: Codable {
    let name: String
    let location: String
    let countryCode: String?
}

struct ProviderStats: Codable {
    let successfulLaunches: Int
    let failedLaunches: Int
}
