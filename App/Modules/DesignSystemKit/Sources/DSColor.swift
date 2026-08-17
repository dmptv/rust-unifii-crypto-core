import SwiftUI
import UIKit

extension Color {
    /// Builds a color that switches between a light and a dark value based
    /// on the current UITraitCollection, the same mechanism system colors
    /// (like Color.primary) use.
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// Semantic names instead of raw colors, so a screen says *what* a color
// means (its role) rather than which literal color it happens to be today.
//
// Each token below is genuinely adaptive - it has both a light and a dark
// value. The app currently forces .preferredColorScheme(.dark) in
// RootView, so only the `dark:` side is visible today, and it matches
// exactly what was hardcoded per-screen before this module existed.
// Removing that forced scheme later is a one-line change in RootView, not
// a per-screen rewrite - these tokens are already ready for it.
public enum DSColor {
    public static let background = Color(light: .white, dark: .black)
    public static let textPrimary = Color(light: .black, dark: .white)
    public static let textSecondary = Color(light: .gray, dark: .gray)
    public static let error = Color(light: .red, dark: .red)
    public static let success = Color(light: .green, dark: .green)
    public static let accent = Color(light: .blue, dark: .blue)
    public static let surface = Color(light: Color.black.opacity(0.05), dark: Color.white.opacity(0.08))
    public static let divider = Color(light: Color.black.opacity(0.1), dark: Color.white.opacity(0.15))
}
