// File: ShareSheet.swift – Location: Utilities (or Views/Common)
import SwiftUI
import UIKit

/// A UIViewControllerRepresentable struct that wraps UIActivityViewController to enable sharing functionality.
/// Major improvements added:
/// 1) completion handler to track share results (UIActivity.ActivityType?, Bool, [Any]?, Error?).
/// 2) optional subject line for email-based shares.
/// 3) popover support for iPad (sourceRect/sourceView).
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    /// You can pass in custom UIActivities if needed
    let applicationActivities: [UIActivity]? = nil
    
    /// Activities to exclude from the share sheet
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    /// Optional share completion handler
    var completion: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)? = nil
    
    /// Optional subject line for email shares
    var subject: String? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        controller.excludedActivityTypes = excludedActivityTypes
        
        // Add a subject for email-like shares
        if let subject {
            controller.setValue(subject, forKey: "subject")
        }
        
        // Track share completion
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            completion?(activityType, completed, returnedItems, error)
        }
        
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No dynamic updates needed
    }
}
