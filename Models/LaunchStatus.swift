// Models/LaunchStatus.swift

import Foundation

enum LaunchStatus: String, Codable {
    case upcoming
    case launching
    case successful
    case failed
    case delayed
    case cancelled
    case unknown
    
    init(fromAPIStatus status: String) {
        let lowercasedStatus = status.lowercased()
        switch lowercasedStatus {
        case let s where s.contains("go"):
            self = .upcoming
        case let s where s.contains("success"):
            self = .successful
        case let s where s.contains("fail"):
            self = .failed
        case let s where s.contains("hold"):
            self = .delayed
        case let s where s.contains("in flight"):
            self = .launching
        case let s where s.contains("cancel"):
            self = .cancelled
        default:
            self = .unknown
        }
    }
    
    var displayText: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .launching: return "Launching"
        case .successful: return "Successful"
        case .failed: return "Failed"
        case .delayed: return "Delayed"
        case .cancelled: return "Cancelled"
        case .unknown: return "Unknown"
        }
    }
}
