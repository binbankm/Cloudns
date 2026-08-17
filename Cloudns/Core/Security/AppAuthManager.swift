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
    
    private init() {
        checkBiometry()
    }
    
    func checkBiometry() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.biometryType = context.biometryType
        } else {
            self.biometryType = .none
        }
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
            
            let context = LAContext()
            context.localizedCancelTitle = "Cancel"
            var error: NSError?
            let reason = "Unlock Cloudns to manage your Cloudflare infrastructure."
            
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                do {
                    let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                    self.isUnlocked = success
                    if success {
                        HapticManager.notification(.success)
                    }
                } catch {
                    self.isUnlocked = false
                }
            } else {
                self.isUnlocked = true
            }
        }
    }
}
