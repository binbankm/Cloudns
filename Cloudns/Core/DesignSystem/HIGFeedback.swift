import SwiftUI
import UIKit

// MARK: - Apple HIG Feedback & Haptics

/// Unified Taptic Engine feedback manager adhering to Apple HIG
@MainActor
public enum HIGFeedback {
    
    /// Checks whether haptics are enabled in user settings (defaults to true)
    public static var isHapticsEnabled: Bool {
        if UserDefaults.standard.object(forKey: AppStorageKey.hapticsEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppStorageKey.hapticsEnabled)
    }
    
    /// Triggers subtle selection feedback (toggles, pickers, light taps)
    public static func selection() {
        guard isHapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// Triggers impact haptic feedback
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Triggers success notification haptic feedback
    public static func success() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Triggers warning notification haptic feedback
    public static func warning() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Triggers error notification haptic feedback
    public static func error() {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// Triggers notification haptic feedback of specified type
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Triggers copy-to-clipboard haptic feedback
    public static func copied() {
        impact(.light)
    }
    
    /// Triggers toggle/selection changed haptic feedback
    public static func toggled() {
        selection()
    }
    
    /// Triggers destructive action haptic feedback
    public static func destructive() {
        impact(.medium)
    }
}

// MARK: - Legacy Compatibility

@MainActor
public enum HapticManager {
    public static func selection() {
        HIGFeedback.selection()
    }
    
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        HIGFeedback.impact(style)
    }
    
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        HIGFeedback.notification(type)
    }
}
