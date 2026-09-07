import SwiftUI
import UIKit

// MARK: - QuickActionModifiers
// iOS 16.0+ Clean Quick Action Helpers for Apple HIG compliance

/// Copies text to the system pasteboard with light impact haptic feedback and optional toast confirmation.
@MainActor
public func copyToClipboard(_ text: String, toast: LocalizedStringKey? = nil) {
    guard !text.isEmpty else { return }
    UIPasteboard.general.string = text
    HapticManager.copied()
    if let toast {
        ToastManager.shared.showCopied(toast)
    }
}

public extension View {
    /// Adds a standardized copy button action to any view.
    func copyOnTap(text: String, toast: LocalizedStringKey? = nil) -> some View {
        Button {
            copyToClipboard(text, toast: toast)
        } label: {
            self
        }
        .buttonStyle(.plain)
    }
}
