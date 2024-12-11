// Models/SpaceDevsResponse.swift

import Foundation

struct SpaceDevsResponse: Codable {
    let count: Int?
    let next: String?
    let previous: String?
    let results: [SpaceDevsLaunch]
    
    enum CodingKeys: String, CodingKey {
        case count
        case next
        case previous
        case results
    }
}

