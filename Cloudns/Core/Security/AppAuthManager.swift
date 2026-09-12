import Combine
import Foundation
import LocalAuthentication
import SwiftUI

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
        isDeviceAuthAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometryType = context.biometryType
        } else {
            biometryType = .none
        }
    }

    var biometryName: String {
        switch biometryType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        default: String(localized: "Passcode")
        }
    }

    var biometryIcon: String {
        switch biometryType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        default: "lock.fill"
        }
    }

    var biometryBadgeText: LocalizedStringKey {
        switch biometryType {
        case .faceID: "Face ID & Local Keys"
        case .touchID: "Touch ID & Local Keys"
        default: "Passcode & Local Keys"
        }
    }

    func verifyBiometrics(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Cancel")
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isDeviceAuthAvailable = false
            HapticManager.notification(.error)
            return false
        }

        isDeviceAuthAvailable = true
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
            isUnlocked = false
        }
    }

    func handleAppWillEnterForeground() {
        let isAppLockEnabled = UserDefaults.standard.bool(forKey: AppStorageKey.isAppLockEnabled)
        guard isAppLockEnabled else {
            isUnlocked = true
            return
        }

        // Only proceed if app actually transitioned from background (ignores Face ID modal / Control Center dismissal)
        guard isInBackground else { return }
        isInBackground = false

        let timeout = UserDefaults.standard.integer(forKey: AppStorageKey.autoLockTimeout)
        let lastTime = UserDefaults.standard.double(forKey: AppStorageKey.lastBackgroundTime)
        let elapsed = Date().timeIntervalSince1970 - lastTime

        if timeout > 0, lastTime > 0, elapsed < Double(timeout) {
            // Still within grace period, keep unlocked!
            return
        }

        // Timeout exceeded or immediately lock
        isUnlocked = false
        authenticate()
    }

    func authenticate() {
        guard !isUnlocked, !isAuthenticating else { return }

        let isAppLockEnabled = UserDefaults.standard.bool(forKey: AppStorageKey.isAppLockEnabled)
        guard isAppLockEnabled else {
            isUnlocked = true
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
