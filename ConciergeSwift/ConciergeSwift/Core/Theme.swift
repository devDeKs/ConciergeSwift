//
//  Theme.swift
//  ConciergeSwift
//
//  Design system colors and styling - ORIGINAL DESIGN
//  Pattern: Dark header + Light content sections
//

import SwiftUI

enum Theme {
    // MARK: - Primary Colors
    static let gold = Color(hex: "B4975A")
    static let midnight = Color(hex: "020410")
    static let midnightLight = Color(hex: "0A0E1A")
    
    // MARK: - Light Mode Colors (Content Areas)
    static let background = Color.white
    static let surface = Color(hex: "F9FAFB") // gray-50
    static let surfaceHover = Color(hex: "F3F4F6") // gray-100
    
    // MARK: - Text Colors (Light Mode)
    static let textPrimary = Color(hex: "111827") // gray-900
    static let textSecondary = Color(hex: "6B7280") // gray-500
    static let textTertiary = Color(hex: "9CA3AF") // gray-400
    
    // MARK: - Text Colors (Dark Header)
    static let textWhite = Color.white
    static let textWhite50 = Color.white.opacity(0.5)
    static let textWhite70 = Color.white.opacity(0.7)
    
    // MARK: - Status Colors
    static let success = Color(hex: "34D399") // emerald-400
    static let error = Color(hex: "FB7185") // rose-400
    static let errorBg = Color(hex: "FEE2E2") // rose-100
    static let warning = Color(hex: "FBBF24") // amber-400
    
    // MARK: - Border Colors
    static let borderLight = Color(hex: "E5E7EB") // gray-200
    static let borderGold = gold.opacity(0.2)
    
    // MARK: - Tab Bar Colors
    static let tabBarBg = Color.white
    static let tabBarBorder = Color(hex: "E5E7EB")
    static let tabBarActive = gold
    static let tabBarInactive = Color(hex: "9CA3AF")
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
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

// MARK: - View Modifiers
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? Theme.gold.opacity(0.8) : Theme.gold)
            .foregroundColor(Theme.midnight)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct LightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Theme.surface)
            .foregroundColor(Theme.textPrimary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func goldButton() -> some View {
        self.buttonStyle(GoldButtonStyle())
    }
    
    func lightButton() -> some View {
        self.buttonStyle(LightButtonStyle())
    }
}
