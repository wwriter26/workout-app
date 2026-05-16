import SwiftUI

// MARK: - App Colors
// These map directly to the JSX dark-theme palette.
enum AppColor {
    // Background layers
    static let appBackground     = Color(hex: "#0A0A0A")
    static let cardBackground    = Color(hex: "#141414")
    static let cardBackground2   = Color(hex: "#1A1A1A")
    static let border1           = Color(hex: "#1F1F1F")
    static let border2           = Color(hex: "#2D2D2D")
    static let navBackground     = Color(hex: "#0D0D0D")

    // Text
    static let textPrimary       = Color(hex: "#F9FAFB")
    static let textSecondary     = Color(hex: "#E5E7EB")
    static let textMuted         = Color(hex: "#9CA3AF")
    static let textDimmed        = Color(hex: "#6B7280")
    static let textFaint         = Color(hex: "#4B5563")
    static let textVeryFaint     = Color(hex: "#374151")

    // Season accents
    static let spring            = Color(hex: "#22C55E")
    static let springAccent      = Color(hex: "#16A34A")
    static let summer            = Color(hex: "#F59E0B")
    static let summerAccent      = Color(hex: "#D97706")
    static let fall              = Color(hex: "#EF4444")
    static let fallAccent        = Color(hex: "#DC2626")
    static let winter            = Color(hex: "#3B82F6")
    static let winterAccent      = Color(hex: "#2563EB")

    // CNS load
    static let cnsHigh           = Color(hex: "#EF4444")
    static let cnsModerateHigh   = Color(hex: "#F97316")
    static let cnsModerate       = Color(hex: "#F59E0B")
    static let cnsLow            = Color(hex: "#22C55E")
    static let cnsRest           = Color(hex: "#374151")

    // Misc
    static let deload            = Color(hex: "#A78BFA")
    static let deloadBg          = Color(hex: "#7C3AED").opacity(0.13)
    static let infoBlue          = Color(hex: "#3B82F6")
    static let dangerRed         = Color(hex: "#EF4444")
}

// MARK: - Typography Helpers
// JSX uses DM Sans (body/headings) and DM Mono (labels, numbers).
// On iOS we map DM Sans → system default and DM Mono → system monospaced.
extension Font {
    // Headings (DM Sans 800/700/600 equivalents)
    static var appHero: Font    { .system(size: 28, weight: .bold,        design: .default) }
    static var appTitle: Font   { .system(size: 18, weight: .heavy,       design: .default) }
    static var appHeading: Font { .system(size: 16, weight: .bold,        design: .default) }
    static var appSubhead: Font { .system(size: 14, weight: .semibold,    design: .default) }
    static var appBody: Font    { .system(size: 12, weight: .regular,     design: .default) }
    static var appSmall: Font   { .system(size: 11, weight: .regular,     design: .default) }

    // Monospaced (DM Mono equivalents)
    static var monoLarge: Font  { .system(size: 28, weight: .semibold,    design: .monospaced) }
    static var monoBig: Font    { .system(size: 20, weight: .semibold,    design: .monospaced) }
    static var monoMid: Font    { .system(size: 14, weight: .semibold,    design: .monospaced) }
    static var monoSmall: Font  { .system(size: 11, weight: .semibold,    design: .monospaced) }
    static var monoLabel: Font  { .system(size: 10, weight: .semibold,    design: .monospaced) }
    static var monoTiny: Font   { .system(size: 9,  weight: .semibold,    design: .monospaced) }
}

// MARK: - Color(hex:) initialiser
extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    /// Standard dark card style used throughout the app.
    func appCard() -> some View {
        self
            .padding(14)
            .background(AppColor.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColor.border1, lineWidth: 1)
            )
    }

    /// Uppercase mono label style (maps to JSX `styles.label`).
    func labelStyle(color: Color = AppColor.textFaint) -> some View {
        self
            .font(.monoLabel)
            .foregroundColor(color)
            .textCase(.uppercase)
            .tracking(1.5)
    }
}
