import CoreGraphics

// A fixed step scale instead of hand-picked numbers per screen. Values
// that don't fit this scale (e.g. clearance for the custom tab bar) are
// layout-specific, not content spacing, and are left as raw literals on
// purpose - forcing everything onto one scale would hide that distinction.
public enum DSSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 40
}
