// Utilities/ThemeColors.swift

import SwiftUI

struct ThemeColors {
    static let cosmicBlue = Color(hex: "0077FF") // For "Upcoming" status
    static let launchGreen = Color(hex: "32CD32") // For "Launching" status
    static let marsRed = Color(hex: "FF4500") // For "Failed" status
    static let solarOrange = Color(hex: "FFA500") // For "Delayed" status
    static let neutralGray = Color(hex: "A9A9A9") // For "To Be Determined" status
    static let brightYellow = Color(hex: "D7FF00") // For "Successful" status
    static let almostWhite = Color(hex: "F5F5F5") // For light text
    static let lightGray = Color(hex: "D3D3D3") // For subdued text
    static let darkGray = Color(hex: "2C2C2E") // For backgrounds
    static let spaceBlack = Color(hex: "000000") // For primary backgrounds
    static let midGray = Color(hex: "6B6B6B") // For mid-range grays
    static let black = Color.black // For accent text or borders
}

// Extension to initialize Color with hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
