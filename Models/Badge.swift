// Models/Badge.swift

import Foundation

enum Badge: String, Codable, Identifiable {
    case live
    case exclusive
    case firstLaunch
    case notable
    
    // Use rawValue as the unique identifier
    var id: String { rawValue }
    
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
