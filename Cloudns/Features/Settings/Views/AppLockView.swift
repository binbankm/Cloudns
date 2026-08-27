import SwiftUI
import LocalAuthentication

struct AppLockView: View {
    // MARK: - Properties
    @ObservedObject private var authManager = AppAuthManager.shared
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Clean native privacy material
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Tap anywhere to re-trigger biometric prompt if dismissed
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.impact(.light)
                    authManager.authenticate()
                }
            
            VStack {
                Spacer()
                
                // Subtle fallback trigger if Face ID prompt was dismissed/cancelled
                Button {
                    HapticManager.impact(.light)
                    authManager.authenticate()
                } label: {
                    Label("Tap to Unlock", systemImage: "lock.open.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, CloudnsSpacing.md)
                        .padding(.vertical, CloudnsSpacing.sm)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, CloudnsSpacing.xxl)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AppLockView()
}
