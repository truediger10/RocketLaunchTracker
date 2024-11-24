import SwiftUI

struct ThemeColors {
    static let spaceBlack = Color(hex: "121212")
    static let darkGray = Color(hex: "2E2E2E")
    static let midGray = Color(hex: "4F4F4F")
    static let lightGray = Color(hex: "B3B3B3")
    static let almostWhite = Color(hex: "E5E5E5")
    static let neonBlue = Color(hex: "00BFFF")
    static let lunarRock = Color(hex: "7A7D7C")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 3:
            (r, g, b) = (
                Double((int >> 8) & 0xF) / 15.0,
                Double((int >> 4) & 0xF) / 15.0,
                Double(int & 0xF) / 15.0
            )
        case 6:
            (r, g, b) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0
            )
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: r, green: g, blue: b)
    }
}
