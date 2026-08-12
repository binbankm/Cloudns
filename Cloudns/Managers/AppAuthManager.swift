import Foundation
import LocalAuthentication
import SwiftUI
import Combine

class AppAuthManager: ObservableObject {
    static let shared = AppAuthManager()
    
    @Published var isUnlocked = false
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock Cloudns to manage your Cloudflare account."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                    } else {
                        // Failed to authenticate
                        self.isUnlocked = false
                    }
                }
            }
        } else {
            // No biometrics available, fallback to passcode
            let reason = "Unlock Cloudns with your device passcode."
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            self.isUnlocked = true
                        } else {
                            self.isUnlocked = false
                        }
                    }
                }
            } else {
                // Device has no passcode set, just unlock
                DispatchQueue.main.async {
                    self.isUnlocked = true
                }
            }
        }
    }
}
