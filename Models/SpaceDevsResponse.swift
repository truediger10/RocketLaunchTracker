// Models/SpaceDevsResponse.swift

import Foundation

struct SpaceDevsResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Launch]
}
