// Utilities/Notification+Extensions.swift

import Foundation

extension Notification.Name {
    /// Notification posted when launch data is updated.
    static let launchDataUpdated = Notification.Name("launchDataUpdated")
    
    /// Notification posted when launch enrichment is updated.
    static let launchEnrichmentUpdated = Notification.Name("launchEnrichmentUpdated")
}
