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

// MARK: - Editorial typography

extension Font {
    /// Serif display face (New York) for titles: gives the app an editorial, premium voice.
    static func serif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Small uppercase label style used for overlines.
    static let overline = Font.system(size: 11, weight: .semibold).width(.expanded)
}

// MARK: - Surfaces

/// App-wide background: deep ink with a faint gold glow at the top and a Nile-blue
/// glow lower down. Flat light grey in light mode.
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Theme.background
            if scheme == .dark {
                RadialGradient(colors: [Color(hex: 0xD9B44A, alpha: 0.13), .clear],
                               center: .init(x: 0.15, y: -0.05), startRadius: 10, endRadius: 420)
                RadialGradient(colors: [Color(hex: 0x2E6BE6, alpha: 0.10), .clear],
                               center: .init(x: 1.0, y: 0.35), startRadius: 10, endRadius: 380)
            } else {
                RadialGradient(colors: [Color(hex: 0xD9B44A, alpha: 0.10), .clear],
                               center: .init(x: 0.15, y: -0.05), startRadius: 10, endRadius: 420)
            }
        }
        .ignoresSafeArea()
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = Theme.Spacing.l
    var radius: CGFloat = Theme.Radius.large

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [Theme.highlight, Theme.stroke],
                                               startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: Theme.shadow, radius: 18, x: 0, y: 10)
            }
    }
}

extension View {
    func cardStyle(padding: CGFloat = Theme.Spacing.l, radius: CGFloat = Theme.Radius.large) -> some View {
        modifier(CardStyle(padding: padding, radius: radius))
    }
}

extension Theme {
    /// Top-edge highlight on cards (catches the light like glass).
    static let highlight = Color.dynamic(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.9, darkAlpha: 0.10)
    static let shadow = Color.dynamic(light: 0x1B2540, dark: 0x000000, lightAlpha: 0.07, darkAlpha: 0.35)
    static let onGold = Color(hex: 0x1A1406)
}

// MARK: - Buttons

/// Subtle scale-down on press for tappable cards and buttons.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// Large pill button: gold (primary), red (destructive) or outlined.
struct PillButtonStyle: ButtonStyle {
    enum Kind { case gold, positive, negative, outline }
    var kind: Kind = .gold

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(foreground)
            .background {
                Capsule(style: .continuous).fill(fill)
                if kind == .outline { Capsule(style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1.5) }
            }
            .shadow(color: glow, radius: configuration.isPressed ? 4 : 14, y: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .gold: return Theme.onGold
        case .positive, .negative: return .white
        case .outline: return Theme.textPrimary
        }
    }

    private var fill: AnyShapeStyle {
        switch kind {
        case .gold: return AnyShapeStyle(Theme.goldGradient)
        case .positive: return AnyShapeStyle(Theme.positive)
        case .negative: return AnyShapeStyle(Theme.negative)
        case .outline: return AnyShapeStyle(Theme.surfaceMuted)
        }
    }

    private var glow: Color {
        switch kind {
        case .gold: return Theme.gold.opacity(0.35)
        case .positive: return Theme.positive.opacity(0.3)
        case .negative: return Theme.negative.opacity(0.3)
        case .outline: return .clear
        }
    }
}
