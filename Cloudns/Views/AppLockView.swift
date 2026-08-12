import SwiftUI

struct AppLockView: View {
    @StateObject private var authManager = AppAuthManager.shared
    
    var body: some View {
        ZStack {
            // Blur effect over the background
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 20)
                
                Text("App Locked")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock Cloudns to continue managing your domains.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    authManager.authenticate()
                }) {
                    Text("Unlock")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
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
