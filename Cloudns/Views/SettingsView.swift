import SwiftUI

struct SettingsView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("themePreference") private var themePreference = "system"
    @AppStorage("appLanguage") private var appLanguage = "system"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    @State private var showingLogoutAlert = false
    @State private var showingClearCacheAlert = false
    @StateObject private var accountManager = AccountManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Card Section
                Section {
                    NavigationLink(destination: AccountsView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [.orange, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 54, height: 54)
                                    .shadow(color: Color.orange.opacity(0.25), radius: 6, x: 0, y: 3)
                                
                                Text(accountManager.activeEmail.prefix(1).uppercased())
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("Active Account")
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.12))
                                        .foregroundStyle(.orange)
                                        .cornerRadius(4)
                                }
                                
                                Text(accountManager.activeEmail.isEmpty ? "No Account Selected" : accountManager.activeEmail)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                
                                Text("Tap to switch or add accounts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // MARK: - Cloudflare Operations & Status
                Section {
                    NavigationLink(destination: CloudflareStatusView()) {
                        HStack(spacing: 14) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.body)
                                .foregroundStyle(.green)
                                .frame(width: 32, height: 32)
                                .background(Color.green.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("System Status")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text("Live Cloudflare network & service health")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    NavigationLink(destination: AuditLogsView(accountId: "")) {
                        HStack(spacing: 14) {
                            Image(systemName: "list.bullet.rectangle.portrait.fill")
                                .font(.body)
                                .foregroundStyle(.blue)
                                .frame(width: 32, height: 32)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Audit Logs")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text("Account change history & actor records")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Cloudflare Services")
                }
                
                // MARK: - Security Section
                Section {
                    Toggle(isOn: $isAppLockEnabled) {
                        SettingsRowView(
                            icon: "faceid",
                            color: .green,
                            title: "App Lock"
                        )
                    }
                    .onChange(of: isAppLockEnabled) { _ in
                        if hapticsEnabled {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }
                } header: {
                    Text("Security")
                } footer: {
                    Text("Require Face ID or Touch ID to unlock the app when returning from the background.")
                }
                
                // MARK: - Preferences & Appearance Section
                Section {
                    Picker(selection: $themePreference) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    } label: {
                        SettingsRowView(
                            icon: "paintbrush.fill",
                            color: .orange,
                            title: "Appearance"
                        )
                    }
                    .pickerStyle(.menu)
                    .onChange(of: themePreference) { _ in
                        if hapticsEnabled {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }
                    
                    Picker(selection: $appLanguage) {
                        Text("Follow System").tag("system")
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    } label: {
                        SettingsRowView(
                            icon: "globe",
                            color: .blue,
                            title: "Language"
                        )
                    }
                    .pickerStyle(.menu)
                    .onChange(of: appLanguage) { _ in
                        if hapticsEnabled {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }
                    
                    Toggle(isOn: $hapticsEnabled) {
                        SettingsRowView(
                            icon: "hand.tap.fill",
                            color: .purple,
                            title: "Haptic Feedback"
                        )
                    }
                    
                    Button {
                        showingClearCacheAlert = true
                    } label: {
                        HStack {
                            SettingsRowView(
                                icon: "trash.fill",
                                color: .red,
                                title: "Clear Local Cache"
                            )
                            Spacer()
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Preferences")
                }
                
                // MARK: - Support & About Section
                Section {
                    NavigationLink(destination: FeedbackView()) {
                        SettingsRowView(
                            icon: "envelope.badge.fill",
                            color: .blue,
                            title: "Feedback & Diagnostics"
                        )
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/binbankm/Cloudns") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        SettingsRowView(
                            icon: "chevron.left.forwardslash.chevron.right",
                            color: .black,
                            title: "GitHub Repository"
                        )
                    }
                    .foregroundStyle(.primary)
                    
                    Button(action: {
                        if let url = URL(string: "https://www.cloudflare.com/privacypolicy/") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        SettingsRowView(
                            icon: "shield.fill",
                            color: .cyan,
                            title: "Privacy Policy"
                        )
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("About & Support")
                } footer: {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    Text("Cloudns v\(version) (\(build))\nMade with ❤️ for Cloudflare users")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                
                // MARK: - Log Out Section
                Section {
                    Button(role: .destructive, action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear Local Cache", isPresented: $showingClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    URLCache.shared.removeAllCachedResponses()
                    ToastManager.shared.showSuccess("Cache Cleared", message: "Local network cache purged")
                }
            } message: {
                Text("Are you sure you want to clear cached network responses and temporary storage?")
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    let loginVM = LoginViewModel()
                    loginVM.logout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to log out of your Cloudflare account?")
            }
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}
