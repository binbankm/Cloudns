import Foundation
import LocalAuthentication
import SwiftUI
import Combine

@MainActor
final class AppAuthManager: ObservableObject {
    static let shared = AppAuthManager()
    
    @Published var isUnlocked = false
    @Published var isAuthenticating = false
    @Published var biometryType: LABiometryType = .none
    
    @Published var isDeviceAuthAvailable: Bool = true
    
    private var isInBackground = false
    
    private init() {
        checkBiometry()
    }
    
    func checkBiometry() {
        let context = LAContext()
        var error: NSError?
        self.isDeviceAuthAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.biometryType = context.biometryType
        } else {
            self.biometryType = .none
        }
    }
    
    var biometryName: String {
        switch biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return String(localized: "Passcode")
        }
    }
    
    func verifyBiometrics(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Cancel")
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            self.isDeviceAuthAvailable = false
            HapticManager.notification(.error)
            return false
        }
        
        self.isDeviceAuthAvailable = true
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                HapticManager.notification(.success)
            } else {
                HapticManager.notification(.warning)
            }
            return success
        } catch {
            HapticManager.notification(.warning)
            return false
        }
    }
    
    func handleAppDidEnterBackground() {
        let isAppLockEnabled = UserDefaults.standard.bool(forKey: AppStorageKey.isAppLockEnabled)
        guard isAppLockEnabled else { return }
        
        isInBackground = true
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: AppStorageKey.lastBackgroundTime)
        let timeout = UserDefaults.standard.integer(forKey: AppStorageKey.autoLockTimeout)
        
        if timeout == 0 {
            self.isUnlocked = false
        }
    }
    
    func handleAppWillEnterForeground() {
        let isAppLockEnabled = UserDefaults.standard.bool(forKey: AppStorageKey.isAppLockEnabled)
        guard isAppLockEnabled else {
            self.isUnlocked = true
            return
        }
        
        // Only proceed if app actually transitioned from background (ignores Face ID modal / Control Center dismissal)
        guard isInBackground else { return }
        isInBackground = false
        
        let timeout = UserDefaults.standard.integer(forKey: AppStorageKey.autoLockTimeout)
        let lastTime = UserDefaults.standard.double(forKey: AppStorageKey.lastBackgroundTime)
        let elapsed = Date().timeIntervalSince1970 - lastTime
        
        if timeout > 0 && lastTime > 0 && elapsed < Double(timeout) {
            // Still within grace period, keep unlocked!
            return
        }
        
        // Timeout exceeded or immediately lock
        self.isUnlocked = false
        authenticate()
    }
    
    func authenticate() {
        guard !isUnlocked, !isAuthenticating else { return }
        
        let isAppLockEnabled = UserDefaults.standard.bool(forKey: AppStorageKey.isAppLockEnabled)
        guard isAppLockEnabled else {
            self.isUnlocked = true
            return
        }
        
        isAuthenticating = true
        checkBiometry()
        
        Task { @MainActor in
            defer { self.isAuthenticating = false }
            
            let reason = String(localized: "Unlock Cloudns to manage your Cloudflare infrastructure.")
            let success = await verifyBiometrics(reason: reason)
            
            withAnimation(.easeInOut(duration: 0.25)) {
                self.isUnlocked = success
            }
        }
    }
}
