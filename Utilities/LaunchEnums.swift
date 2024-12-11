// Utilities/LaunchEnums.swift

import Foundation
import SwiftUI

/// Represents different types of badges for launches.
enum Badge: String, Codable, Identifiable {
    case live = "Live"
    case exclusive = "Exclusive"
    case firstLaunch = "First Launch"
    case notable = "Notable" // New badge type

    var id: String { self.rawValue }

    /// Provides the display text for the badge.
    var displayText: String {
        self.rawValue
    }

    /// Provides the background color for the badge based on its type.
    var color: Color {
        switch self {
        case .live:
            return ThemeColors.red
        case .exclusive:
            return ThemeColors.purple
        case .firstLaunch:
            return ThemeColors.blue
        case .notable:
            return ThemeColors.orange
        }
    }
}

/// Represents the status of a launch.
enum LaunchStatus: String, Codable, Identifiable {
    case upcoming
    case launching
    case successful
    case failed
    case delayed
    case cancelled
    case unknown // Added case

    var id: String { self.rawValue }

    /// Provides the display text for the launch status.
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

    /// Provides the color associated with each launch status.
    var color: Color {
        switch self {
        case .successful:
            return ThemeColors.brightYellow
        case .upcoming:
            return ThemeColors.neonBlue
        case .launching:
            return .green
        case .failed:
            return .red
        case .delayed:
            return .orange
        case .cancelled:
            return .gray
        case .unknown:
            return ThemeColors.lunarRock
        }
    }
}
