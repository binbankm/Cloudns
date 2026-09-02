import SwiftUI

// MARK: - Apple HIG Accessibility-Aware Motion System
// Automatically respects user's Reduce Motion preference (System Accessibility Settings)

public enum HIGMotion {
    
    /// Interactive spring animation (respects Reduce Motion accessibility preference)
    public static func interactiveSpring(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.15)
            : .spring(response: 0.28, dampingFraction: 0.72)
    }
    
    /// Card and sheet presentation spring animation
    public static func cardSpring(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeInOut(duration: 0.2)
            : .spring(response: 0.35, dampingFraction: 0.78)
    }
    
    /// Overlay HUD presentation spring animation
    public static func overlaySpring(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeInOut(duration: 0.2)
            : .spring(response: 0.32, dampingFraction: 0.82)
    }
}
