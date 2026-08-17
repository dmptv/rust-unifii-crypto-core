import CoreGraphics

// Named SF Symbols instead of a string literal picked by hand at each call
// site - keeps the same icon meaning (e.g. "back") from silently drifting
// to a different symbol in one screen but not another.
public enum DSIcon {
    public static let back = "chevron.left"
    public static let success = "checkmark.circle.fill"
    public static let tabLive = "chart.line.uptrend.xyaxis"
    public static let tabNews = "newspaper"
    public static let tabWatchlist = "star"
    public static let tabAsync = "arrow.triangle.2.circlepath"
    public static let tabGrpc = "bubble.left.and.bubble.right"
    public static let tabPush = "bell.badge"
    public static let browseList = "list.bullet"
}

// A fixed size scale for icons, the same idea as DSSpacing/DSFont: pick a
// few sizes, use them everywhere, instead of a different number per call
// site with no shared rule.
public enum DSIconSize {
    public static let small: CGFloat = 16
    public static let medium: CGFloat = 24
    public static let large: CGFloat = 40
}
