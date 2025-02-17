//
//  LaunchEnums.swift
//  RocketLaunchTracker
//
import Foundation
import SwiftUI

// MARK: - LaunchStatus
enum LaunchStatus: String, Codable, Equatable, Hashable {
    case upcoming
    case launching
    case successful
    case failed
    case delayed
    case cancelled
    case unknown

    var displayText: String {
        switch self {
        case .upcoming:    return "Upcoming"
        case .launching:   return "Launching"
        case .successful:  return "Successful"
        case .failed:      return "Failed"
        case .delayed:     return "Delayed"
        case .cancelled:   return "Cancelled"
        case .unknown:     return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .upcoming, .launching: return ThemeColors.orange
        case .successful:           return ThemeColors.neonBlue
        case .failed:               return ThemeColors.purple
        case .delayed:              return ThemeColors.brightYellow
        case .cancelled, .unknown:  return ThemeColors.darkGray
        }
    }
}

// MARK: - Badge
enum Badge: String, Codable, Identifiable, Hashable {
    case live
    case exclusive
    case firstLaunch
    case notable

    var id: String { rawValue }

    var displayText: String {
        switch self {
        case .live:        return "Live"
        case .exclusive:   return "Exclusive"
        case .firstLaunch: return "First Launch"
        case .notable:     return "Notable"
        }
    }
}
