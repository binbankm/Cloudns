import SwiftUI
import UIKit

// MARK: - Gentle Keyboard Dismissal Standards (AGENTS.md)

/// Globally resigns the software keyboard across the application in a safe, standard manner
@MainActor
public func hideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
    for scene in UIApplication.shared.connectedScenes {
        guard let windowScene = scene as? UIWindowScene else { continue }
        for window in windowScene.windows {
            window.endEditing(true)
        }
    }
}

/// Unified pure-SwiftUI ViewModifier that enables HIG-compliant keyboard dismissal:
/// 1. Interactive scrolling dismissal (.scrollDismissesKeyboard(.interactively))
/// 2. Scoped background canvas tap dismissal (zero UIWindow pollution, zero gesture conflict)
public struct GentleKeyboardDismissModifier: ViewModifier {
    public init() {}

    @MainActor
    public func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
    }
}

public extension View {
    /// Resigns the software keyboard across the application
    @MainActor
    func hideKeyboard() {
        Cloudns.hideKeyboard()
    }

    /// Applies the standardized keyboard dismissal policy (interactive scroll + background tap)
    func gentleKeyboardDismissable() -> some View {
        modifier(GentleKeyboardDismissModifier())
    }
}
