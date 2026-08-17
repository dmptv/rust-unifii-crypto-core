import SwiftUI

public enum DSAnimation {
    /// Default motion for state changes (toggles, appearing content).
    public static let standard = Animation.easeInOut(duration: 0.25)
    /// A slow, repeating pulse - used for "live/active" indicators.
    public static let pulse = Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)
}
