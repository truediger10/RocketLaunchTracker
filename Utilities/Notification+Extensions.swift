// Notification+Extensions.swift
import Foundation

/**
 Extensions to `Notification.Name` for custom notifications used within the app.

 By defining custom notification names here, you centralize all notification identifiers,
 making it easier to update and maintain your notification logic. It also improves
 discoverability and reduces the likelihood of typos or mismatches in notification names.
 */
extension Notification.Name {
    /// Posted whenever launch enrichment data is updated. Observers can refresh UI or data accordingly.
    static let launchEnrichmentUpdated = Notification.Name("launchEnrichmentUpdated")
}
