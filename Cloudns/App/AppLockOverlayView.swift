import SwiftUI

/// AppLock 全屏模糊遮罩与解锁触发器
struct AppLockOverlayView: View {
    @ObservedObject var authManager: AppAuthManager
    let scenePhase: ScenePhase
    
    var body: some View {
        let shouldMask = !authManager.isUnlocked || scenePhase != .active
        
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            Image(systemName: "lock.shield.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !authManager.isUnlocked {
                HapticManager.impact(.light)
                authManager.authenticate()
            }
        }
        .opacity(shouldMask ? 1 : 0)
        .allowsHitTesting(!authManager.isUnlocked && scenePhase == .active)
        .animation(.easeInOut(duration: 0.15), value: shouldMask)
    }
}
