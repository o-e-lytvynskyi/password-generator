import SwiftUI

/// VSCode "Dark+" inspired palette.
enum Theme {
    static let windowBackground = Color(hex: 0x1E1E1E)
    static let panelBackground = Color(hex: 0x252526)
    static let inputBackground = Color(hex: 0x3C3C3C)
    static let border = Color(hex: 0x3C3C3C)
    static let focusBorder = Color(hex: 0x007ACC)

    static let textPrimary = Color(hex: 0xCCCCCC)
    static let textSecondary = Color(hex: 0x9D9D9D)

    static let accent = Color(hex: 0x0E639C)
    static let accentHover = Color(hex: 0x1177BB)
    static let success = Color(hex: 0x4EC9B0)

    static let strengthWeak = Color(hex: 0xF14C4C)
    static let strengthMedium = Color(hex: 0xCCA700)
    static let strengthStrong = Color(hex: 0x4EC9B0)

    static func strengthColor(_ s: PasswordStrength) -> Color {
        switch s {
        case .weak: return strengthWeak
        case .medium: return strengthMedium
        case .strong: return strengthStrong
        }
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
