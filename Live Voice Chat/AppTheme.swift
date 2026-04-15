//
//  AppTheme.swift
//  Live Voice Chat
//
//  Created by Mac on 15/04/26.
//

import SwiftUI

// MARK: - Theme
enum AppTheme {
    // App background
    static let appBackground     = Color(hex: "#FAFAFA")
    static let cardBackground    = Color(hex: "#FFFFFF")

    // User bubble — Green
    static let userBubble        = Color(hex: "#4CAF50")
    static let userBubbleLight   = Color(hex: "#E8F5E9")
    static let userBubbleDark    = Color(hex: "#2E7D32")

    // AI bubble — Amber
    static let aiBubble          = Color(hex: "#FFD54F")
    static let aiBubbleLight     = Color(hex: "#FFF8E1")
    static let aiBubbleDark      = Color(hex: "#F9A825")

    // Buttons — Pink
    static let buttonPrimary     = Color(hex: "#FF5C8A")
    static let buttonLight       = Color(hex: "#FFE4EC")
    static let buttonDark        = Color(hex: "#C2185B")

    // Labels / chips — Yellow-Orange
    static let labelPrimary      = Color(hex: "#FFB74D")
    static let labelLight        = Color(hex: "#FFF3E0")
    static let labelDark         = Color(hex: "#EF6C00")

    // Text
    static let textPrimary       = Color(hex: "#212121")
    static let textSecondary     = Color(hex: "#616161")
    static let textPlaceholder   = Color(hex: "#9E9E9E")

    // Font helper — Avenir Next (fallback handled by SwiftUI automatically)
    static func font(_ style: AvenirStyle, size: CGFloat) -> Font {
        .custom(style.rawValue, size: size)
    }

    enum AvenirStyle: String {
        case regular   = "AvenirNext-Regular"
        case medium    = "AvenirNext-Medium"
        case demiBold  = "AvenirNext-DemiBold"
        case bold      = "AvenirNext-Bold"
    }
}


// MARK: - Color Hex Helper
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch h.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
