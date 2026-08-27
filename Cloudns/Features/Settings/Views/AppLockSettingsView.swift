import SwiftUI
import LocalAuthentication

struct AppLockSettingsView: View {
    @AppStorage(AppStorageKey.isAppLockEnabled) private var isAppLockEnabled = false
    @AppStorage(AppStorageKey.autoLockTimeout) private var autoLockTimeout = 0
    // MARK: - Properties
    @ObservedObject private var authManager = AppAuthManager.shared
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    
    private let timeoutOptions: [(title: LocalizedStringKey, seconds: Int)] = [
        ("Immediately", 0),
        ("After 1 minute", 60),
        ("After 2 minutes", 120),
        ("After 5 minutes", 300),
        ("After 30 minutes", 1800)
    ]
    
    // MARK: - Body
    var body: some View {
        List {
            // MARK: - Biometric Requirement Toggle
            Section {
                Toggle(isOn: Binding(
                    get: { isAppLockEnabled },
                    set: { newValue in
                        Task { @MainActor in
                            let reason = newValue
                                ? String(localized: "Verify your identity to enable App Lock.")
                                : String(localized: "Verify your identity to disable App Lock.")
                            let success = await authManager.verifyBiometrics(reason: reason)
                            if success {
                                isAppLockEnabled = newValue
                                if newValue {
                                    authManager.isUnlocked = true
                                }
                            }
                        }
                    }
                )) {
                    toggleLabel
                        .font(.body)
                }
            } footer: {
                footerLabel
            }
            
            // MARK: - Auto-Lock Options (Only shown when Enabled)
            if isAppLockEnabled {
                Section {
                    ForEach(timeoutOptions, id: \.seconds) { option in
                        Button {
                            HapticManager.selection()
                            autoLockTimeout = option.seconds
                        } label: {
                            HStack {
                                Text(option.title)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if autoLockTimeout == option.seconds {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(CloudnsColor.brand)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Auto-Lock")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("App Lock")
        .navigationBarTitleDisplayMode(.inline)
        .id(appLanguage)
    }
    
    @ViewBuilder
    // MARK: - Private Views
    private var toggleLabel: some View {
        switch authManager.biometryType {
        case .faceID:
            Text("Require Face ID")
        case .touchID:
            Text("Require Touch ID")
        default:
            Text("Require Passcode")
        }
    }
    
    @ViewBuilder
    private var footerLabel: some View {
        switch authManager.biometryType {
        case .faceID:
            Text("Unlock the app using Face ID.")
        case .touchID:
            Text("Unlock the app using Touch ID.")
        default:
            Text("Unlock the app using Passcode.")
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AppLockSettingsView()
    }
}
