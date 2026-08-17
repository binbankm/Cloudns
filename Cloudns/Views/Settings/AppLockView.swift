import SwiftUI
import LocalAuthentication

struct AppLockView: View {
    @StateObject private var authManager = AppAuthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    private var biometryIconName: String {
        switch authManager.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.open.fill"
        }
    }
    
    private var biometryButtonTitle: String {
        switch authManager.biometryType {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        default: return "Unlock with Passcode"
        }
    }
    
    var body: some View {
        ZStack {
            // Full frosted blur over background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: biometryIconName)
                        .font(.system(size: 46, weight: .medium))
                        .foregroundStyle(.orange)
                }
                .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    Text("Cloudns Locked")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Verify your identity to continue managing Cloudflare.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                Button(action: {
                    HapticManager.impact(.medium)
                    authManager.authenticate()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: biometryIconName)
                            .font(.body.weight(.semibold))
                        Text(biometryButtonTitle)
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 36)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            authManager.authenticate()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !authManager.isUnlocked {
                authManager.authenticate()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appWillEnterForeground)) { _ in
            if !authManager.isUnlocked {
                authManager.authenticate()
            }
        }
    }
}

#Preview {
    AppLockView()
}
