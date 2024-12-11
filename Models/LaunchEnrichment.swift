// Models/LaunchEnrichment.swift

import Foundation

/**
 Represents additional enrichment data for a launch, such as enhanced short and detailed descriptions.

 This data might be fetched from a cache or enrichment service and merged into the final `Launch` model.
 */
struct LaunchEnrichment: Codable {
    let shortDescription: String
    let detailedDescription: String
}
