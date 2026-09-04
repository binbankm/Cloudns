import SwiftUI
import UIKit

// MARK: - Apple HIG Feedback & Haptics

@MainActor
public enum HapticManager {
    public static var isHapticsEnabled: Bool {
        if UserDefaults.standard.object(forKey: AppStorageKey.hapticsEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppStorageKey.hapticsEnabled)
    }
    
    public static func selection() {
        guard isHapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    public static func success() {
        notification(.success)
    }
    
    public static func warning() {
        notification(.warning)
    }
    
    public static func error() {
        notification(.error)
    }
    
    public static func copied() {
        impact(.light)
    }
    
    public static func toggled() {
        selection()
    }
    
    public static func destructive() {
        impact(.medium)
    }
}

// Backward compatibility forwarder
public typealias HIGFeedback = HapticManager
