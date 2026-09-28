import SwiftUI
import UIKit

/// Central design tokens for EGX Trader.
///
/// The palette is inspired by Cairo at night: a deep ink background, Nile-blue
/// surfaces and a restrained pharaonic gold accent. Every color adapts to light
/// and dark mode.
enum Theme {

    // MARK: Colors

    static let background = Color.dynamic(light: 0xF4F5F8, dark: 0x080B11)
    static let surface = Color.dynamic(light: 0xFFFFFF, dark: 0x111620)
    static let surfaceElevated = Color.dynamic(light: 0xFFFFFF, dark: 0x171D2A)
    static let surfaceMuted = Color.dynamic(light: 0xECEEF3, dark: 0x1C2331)
    static let stroke = Color.dynamic(light: 0x000000, dark: 0xFFFFFF, lightAlpha: 0.06, darkAlpha: 0.07)

    static let textPrimary = Color.dynamic(light: 0x0B1220, dark: 0xF2F4F8)
    static let textSecondary = Color.dynamic(light: 0x5B6475, dark: 0x8C95A8)
    static let textTertiary = Color.dynamic(light: 0x9199A8, dark: 0x5A6275)

    static let gold = Color.dynamic(light: 0xB08A1E, dark: 0xD9B44A)
    static let goldSoft = Color.dynamic(light: 0xB08A1E, dark: 0xD9B44A, lightAlpha: 0.12, darkAlpha: 0.14)
    static let nile = Color.dynamic(light: 0x1F6FEB, dark: 0x4C8DFF)

    static let positive = Color.dynamic(light: 0x0E9F6E, dark: 0x1FD18B)
    static let negative = Color.dynamic(light: 0xD92D3A, dark: 0xFF4D5E)
    static let neutral = Color.dynamic(light: 0x7A8499, dark: 0x8C95A8)
    static let warning = Color.dynamic(light: 0xC77700, dark: 0xFFB020)

    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xF3D98B), Color(hex: 0xD9B44A), Color(hex: 0xA37C18)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            Color.dynamic(light: 0x10213F, dark: 0x0F1F3D),
            Color.dynamic(light: 0x0B1426, dark: 0x0A1224)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func trend(_ value: Double) -> Color {
        if value > 0.00001 { return positive }
        if value < -0.00001 { return negative }
        return neutral
    }

    // MARK: Metrics

    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 22
        static let hero: CGFloat = 28
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
}

// MARK: - Typography

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Numeric font with tabular digits so prices don't jitter when they tick.
    static func numeric(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

// MARK: - Color helpers

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    static func dynamic(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkAlpha)
                : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
