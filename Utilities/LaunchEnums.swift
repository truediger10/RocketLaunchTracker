// Utilities/LaunchEnums.swift

import Foundation
import SwiftUI

/// Represents the status of a launch.
enum LaunchStatus: String, Codable {
    case upcoming
    case launching
    case successful
    case failed
    case delayed
    case cancelled
    case unknown // Added 'unknown' case to handle undefined statuses
    
    var displayText: String {
        switch self {
        case .upcoming:
            return "Upcoming"
        case .launching:
            return "Launching"
        case .successful:
            return "Successful"
        case .failed:
            return "Failed"
        case .delayed:
            return "Delayed"
        case .cancelled:
            return "Cancelled"
        case .unknown:
            return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .upcoming:
            return ThemeColors.orange
        case .launching:
            return ThemeColors.orange
        case .successful:
            return ThemeColors.neonBlue
        case .failed:
            return ThemeColors.purple
        case .delayed:
            return ThemeColors.brightYellow
        case .cancelled:
            return ThemeColors.darkGray
        case .unknown:
            return ThemeColors.darkGray
        }
    }
}

/// Represents badges associated with a launch.
enum Badge: String, Codable, Identifiable { // Conformed to Identifiable
    case live
    case exclusive
    case firstLaunch
    case notable
    
    var id: String { rawValue } // Provided unique identifier
    
    var displayText: String {
        switch self {
        case .live:
            return "Live"
        case .exclusive:
            return "Exclusive"
        case .firstLaunch:
            return "First Launch"
        case .notable:
            return "Notable"
        }
    }
}
