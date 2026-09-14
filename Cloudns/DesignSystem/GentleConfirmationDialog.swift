import SwiftUI

// MARK: - Gentle Confirmation Dialog

public extension View {
    /// Presents a standardized gentle confirmation dialog with automatic warning haptic feedback.
    func gentleConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmTitle: String = "Delete",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            LocalizedStringKey(title),
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(
                LocalizedStringKey(confirmTitle),
                role: confirmRole
            ) {
                if confirmRole == .destructive {
                    GentleHaptics.warning()
                } else {
                    GentleHaptics.selection()
                }
                onConfirm()
            }

            Button("Cancel", role: .cancel) {
                GentleHaptics.soft()
            }
        } message: {
            if let message {
                Text(LocalizedStringKey(message))
            }
        }
        .onChange(of: isPresented.wrappedValue) { newValue in
            if newValue {
                GentleHaptics.warning()
            }
        }
    }
}
