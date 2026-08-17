import SwiftUI

// A fixed type ramp instead of a different .system(size:) picked by hand
// per screen. A few of the original one-off sizes (for example 30pt vs
// 32pt heavy titles, or 18pt vs 20pt emphasis text) get folded into the
// nearest step here - that normalization is the actual point of a scale,
// not an accident.
//
// Accessibility trade-off, stated plainly: the seven custom sizes below
// are fixed points, so they do NOT grow with the user's Dynamic Type
// setting. The five aliases at the bottom (headline/subheadline/body/
// caption/captionBold) map to SwiftUI's own text styles, which DO scale
// automatically. This mirrors a common real-world choice: large numeric
// displays (a price, a hero result) stay a fixed size, while regular
// reading text scales for accessibility.
public enum DSFont {
    /// The single biggest number on a screen (for example Async's ETH price).
    public static let heroNumber = Font.system(size: 38, weight: .heavy, design: .rounded)
    /// Page-level headers ("Markets", "Async", a coin's name).
    public static let screenTitle = Font.system(size: 32, weight: .heavy)
    /// Monetary/price figures.
    public static let priceNumber = Font.system(size: 28, weight: .heavy, design: .rounded)
    /// Sub-screen headers (an article title, a confirm prompt).
    public static let sectionTitle = Font.system(size: 26, weight: .heavy)
    /// Emphasized inline text - error messages, prominent labels.
    public static let emphasis = Font.system(size: 20, weight: .heavy)
    /// A positive/neutral result shown inline, smaller than heroNumber.
    public static let resultText = Font.system(size: 20, weight: .semibold, design: .rounded)
    /// Compact numeric values in list rows (a row's price, a delta).
    public static let numericCompact = Font.system(size: 16, weight: .semibold, design: .rounded)

    /// Scales with Dynamic Type.
    public static let headline = Font.headline
    /// Scales with Dynamic Type.
    public static let subheadline = Font.subheadline
    /// Scales with Dynamic Type.
    public static let body = Font.body
    /// Scales with Dynamic Type.
    public static let caption = Font.caption
    /// Scales with Dynamic Type.
    public static let captionBold = Font.caption.weight(.bold)
}
