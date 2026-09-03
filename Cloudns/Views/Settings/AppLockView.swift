import SwiftUI
import LocalAuthentication

struct AppLockView: View {
    @ObservedObject private var authManager = AppAuthManager.shared
    
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
                    HIGFeedback.impact(.light)
                    authManager.authenticate()
                }
            
            VStack {
                Spacer()
                
                // Subtle fallback trigger if Face ID prompt was dismissed/cancelled
                Button {
                    HIGFeedback.impact(.light)
                    authManager.authenticate()
                } label: {
                    Label("Tap to Unlock", systemImage: "lock.open.fill")
                        .font(HIGTypography.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, HIGTokens.Spacing.lg)
                        .padding(.vertical, HIGTokens.Spacing.sm)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
                .buttonStyle(.higPressable)
                .higTouchTarget()
                .padding(.bottom, HIGTokens.Spacing.huge)
            }
        }
    }
}

#Preview {
    AppLockView()
}
