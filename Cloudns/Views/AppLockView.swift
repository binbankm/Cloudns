import SwiftUI

struct AppLockView: View {
    @StateObject private var authManager = AppAuthManager.shared
    
    var body: some View {
        ZStack {
            // Blur effect over the background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                    .padding(.bottom, 20)
                    .accessibilityHidden(true)
                
                Text("App Locked")
                    .font(.title.weight(.bold))
                
                Text("Unlock Cloudns to continue managing your domains.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    HapticManager.impact(.medium)
                    authManager.authenticate()
                }) {
                    Text("Unlock")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                }
            }
        }
        .onAppear {
            authManager.authenticate()
        }
    }
}

#Preview {
    AppLockView()
}
