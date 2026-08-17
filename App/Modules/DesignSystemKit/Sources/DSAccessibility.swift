import SwiftUI

public enum DSAccessibility {
    /// Apple's Human Interface Guidelines minimum tap target size.
    public static let minTapTarget: CGFloat = 44
}

public extension View {
    /// Guarantees a tappable view (an icon-only button, for example) meets
    /// the 44x44pt minimum tap target, without changing how it looks.
    func minTapTarget() -> some View {
        frame(minWidth: DSAccessibility.minTapTarget, minHeight: DSAccessibility.minTapTarget)
    }
}
