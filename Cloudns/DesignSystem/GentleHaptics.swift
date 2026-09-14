import UIKit

// MARK: - Gentle Haptics Utility

@MainActor
public enum GentleHaptics {
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    /// Gentle selection feedback for tabs, pills, and account switching
    public static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    /// Feather-soft tap feedback for card taps and button clicks
    public static func soft() {
        impactSoft.prepare()
        impactSoft.impactOccurred()
    }

    /// Light impact feedback for successful refresh and toggle
    public static func light() {
        impactLight.prepare()
        impactLight.impactOccurred()
    }

    /// Gentle warning feedback for destructive / delete prompts
    public static func warning() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Success notification feedback for record creation and credentials saved
    public static func success() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }
}
