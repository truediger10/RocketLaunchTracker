// Utilities/ThemeColors.swift

import SwiftUI

/**
 A collection of theme colors used throughout the RocketLaunchTracker app.
 
 These static properties provide a consistent visual style across the UI, making it easy
 to maintain a cohesive look and feel. Each color is defined by a hexadecimal string and
 converted into a `Color` instance using the `Color(hex:)` initializer.
 
 **Accessibility Note:**
 Ensure that the chosen foreground and background colors provide sufficient contrast.
 Consider using dynamic colors or additional accessibility settings when possible.
 */
struct ThemeColors {
    /// A deep black used as a primary background color, evoking the vastness of space.
    static let spaceBlack = Color(hex: "121212")
    
    /// A dark gray providing subtle contrast for secondary backgrounds or dividers.
    static let darkGray = Color(hex: "2E2E2E")
    
    /// A mid-range gray for UI elements that need differentiation from the background
    /// but are not prominent.
    static let midGray = Color(hex: "4F4F4F")
    
    /// A lighter gray shade for secondary text or muted elements.
    static let lightGray = Color(hex: "B3B3B3")
    
    /// A near-white color for text and elements on dark backgrounds.
    static let almostWhite = Color(hex: "E5E5E5")
    
    /// A bright neon blue accent color for emphasis and interactive elements.
    static let neonBlue = Color(hex: "00BFFF")
    
    /// A lunar rock-inspired gray-green for subtle highlights or accenting details.
    static let lunarRock = Color(hex: "7A7D7C")
    
    /// A bright yellow for calls-to-action, highlights, or emphasis on dark backgrounds.
    static let brightYellow = Color(hex: "D7FF00")
    
    /// An orange color used for notable badges.
    static let orange = Color(hex: "FFA500") // Orange
    
    /// A purple color used for exclusive badges.
    static let purple = Color(hex: "800080") // Purple
    
    /// A red color used for live badges.
    static let red = Color(hex: "FF0000") // Red
    
    /// A blue color used for first launch badges.
    static let blue = Color(hex: "0000FF") // Blue
}

/**
 An extension to `Color` allowing initialization from a hexadecimal color code.

 **Usage:**
 ```swift
 let customColor = Color(hex: "FF5733")
 This initializer:
     •    Trims non-alphanumeric characters.
     •    Parses the hex string for either 3-digit (e.g., “FFF”) or 6-digit (e.g., “FFFFFF”) hex colors.
     •    Defaults to black if the hex string is invalid.

 Accessibility Note:
 Ensure chosen colors support sufficient contrast. Use system colors or test designs
 with accessibility tools if unsure.
 */
extension Color {
    /// Initializes a Color from a hex code string.
    /// - Parameter hex: A string representing the color in hex format.
    /// - Note:
    ///   - 3-digit format (e.g., “FFF”) expands to full RGB.
    ///   - 6-digit format (e.g., “FFFFFF”) is standard RGB.
    ///   - Defaults to black if the hex cannot be parsed.
    init(hex: String) {
        let cleanedHex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&int)
        let r, g, b: Double
        switch cleanedHex.count {
        case 3:
            // Expand 3-digit hex into full RGB
            (r, g, b) = (
                Double((int >> 8) & 0xF) / 15.0,
                Double((int >> 4) & 0xF) / 15.0,
                Double(int & 0xF) / 15.0
            )
        case 6:
            // Parse 6-digit hex as standard RRGGBB
            (r, g, b) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0
            )
        default:
            // If invalid, default to black
            (r, g, b) = (0, 0, 0)
        }
        
        self.init(red: r, green: g, blue: b)
    }
}
