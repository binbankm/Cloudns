import SwiftUI

// MARK: - SettingsView
// Apple HIG Compliant Settings Hub (iOS 16.0+)

struct SettingsView: View {
    @AppStorage(AppStorageKey.isAppLockEnabled) private var isAppLockEnabled = false
    @AppStorage(AppStorageKey.themePreference) private var themePreference = "system"
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    @AppStorage(AppStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(AppStorageKey.isLoggedIn) private var isLoggedIn = false
    @Environment(\.openURL) private var openURL
    
    @State private var showingLogoutAlert = false
    @State private var showingClearCacheAlert = false
    @State private var showingAccountSheet = false
    @ObservedObject private var accountManager = AccountManager.shared
    @ObservedObject private var cacheManager = CacheManager.shared
    @ObservedObject private var iconManager = AppIconManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authManager = AppAuthManager.shared
    
    private var biometryIcon: String {
        authManager.biometryIcon
    }
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Card Section
                Section {
                    Button {
                        HapticManager.impact(.light)
                        showingAccountSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            AccountAvatarView(identifier: accountManager.activeEmail, size: 52)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Active Account")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.14))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                                
                                if accountManager.activeEmail.isEmpty {
                                    Text("No Account Selected")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                } else {
                                    Text(verbatim: accountManager.activeEmail)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                                
                                Text("Tap to switch or add accounts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                // MARK: - Cloudflare Operations & Status
                Section {
                    NavigationLink(destination: CloudflareStatusView()) {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "antenna.radiowaves.left.and.right", color: .green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("System Status")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Live Cloudflare network & service health")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    
                    NavigationLink(destination: AuditLogsView()) {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "list.bullet.rectangle.portrait.fill", color: .blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Audit Logs")
                                    .font(.body.weight(.medium))
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
                    NavigationLink {
                        AppLockSettingsView()
                    } label: {
                        HStack {
                            SettingsRowView(
                                icon: biometryIcon,
                                color: .green,
                                title: "App Lock"
                            )
                            
                            Spacer()
                            
                            Text(isAppLockEnabled ? LocalizedStringKey("On") : LocalizedStringKey("Off"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Security")
                }
                
                // MARK: - Preferences & Appearance Section
                Section {
                    Picker(selection: $themePreference) {
                        Text("Follow System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    } label: {
                        SettingsRowView(
                            icon: "circle.righthalf.filled",
                            color: .orange,
                            title: "Appearance"
                        )
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .onChange(of: themePreference) { _ in
                        HapticManager.impact(.light)
                    }
                    
                    NavigationLink {
                        ThemeColorPickerView()
                    } label: {
                        HStack {
                            SettingsRowView(
                                icon: "paintpalette.fill",
                                color: themeManager.currentColor.color,
                                title: "Theme Color"
                            )
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(themeManager.currentColor.color)
                                    .frame(width: 10, height: 10)
                                Text(themeManager.currentColor.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        AppIconPickerView()
                    } label: {
                        HStack {
                            SettingsRowView(
                                icon: "app.badge.fill",
                                color: .pink,
                                title: "App Icon"
                            )
                            Spacer()
                            Text(iconManager.currentIcon.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Picker(selection: $appLanguage) {
                        Text("Follow System").tag("system")
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                        Text("繁體中文").tag("zh-Hant")
                        Text("日本語").tag("ja")
                        Text("한국어").tag("ko")
                        Text("Deutsch").tag("de")
                        Text("Français").tag("fr")
                        Text("Español").tag("es")
                        Text("Português").tag("pt-BR")
                        Text("Italiano").tag("it")
                        Text("Русский").tag("ru")
                        Text("العربية").tag("ar")
                    } label: {
                        SettingsRowView(
                            icon: "globe",
                            color: .blue,
                            title: "Language"
                        )
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .onChange(of: appLanguage) { _ in
                        HapticManager.selection()
                    }
                    
                    Toggle(isOn: $hapticsEnabled) {
                        SettingsRowView(
                            icon: "hand.tap.fill",
                            color: .purple,
                            title: "Haptic Feedback"
                        )
                    }
                    .onChange(of: hapticsEnabled) { enabled in
                        if enabled {
                            HapticManager.impact(.medium)
                        }
                    }
                    
                    Button {
                        HapticManager.impact(.medium)
                        showingClearCacheAlert = true
                    } label: {
                        HStack {
                            SettingsRowView(
                                icon: "trash.fill",
                                color: .orange,
                                title: "Clear Local Cache"
                            )
                            Spacer()
                            if cacheManager.isCalculating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text(cacheManager.formattedCacheSize)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Preferences")
                }
                
                // MARK: - Support
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
                            openURL(url)
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
                            openURL(url)
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
                }
                
                // MARK: - Log Out Section
                Section(footer: appVersionFooter) {
                    Button(role: .destructive, action: {
                        HapticManager.impact(.medium)
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
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await cacheManager.calculateCacheSize()
            }
            .confirmationDialog("Clear Local Cache", isPresented: $showingClearCacheAlert, titleVisibility: .visible) {
                Button("Clear Local Cache", role: .destructive) {
                    Task {
                        await cacheManager.clearAllCaches()
                        ToastManager.shared.showSuccess("Local Cache Cleared", icon: "trash.fill")
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to clear cached network responses and temporary storage?")
            }
            .confirmationDialog("Log Out", isPresented: $showingLogoutAlert, titleVisibility: .visible) {
                Button("Log Out of All Accounts", role: .destructive) {
                    AccountManager.shared.logoutAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out of your Cloudflare account?")
            }
            .sheet(isPresented: $showingAccountSheet) {
                AccountsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Version Footer
    private var appVersionFooter: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        return VStack(spacing: 2) {
            Text("Cloudns v\(appVersion) (\(buildNumber))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Designed for Cloudflare Edge & Zero Trust")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - SettingsRowView

struct SettingsRowView: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    init(icon: String, color: Color, title: LocalizedStringKey) {
        self.icon = icon
        self.color = color
        self.title = title
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: icon, color: color)
            
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
        }
    }
}
