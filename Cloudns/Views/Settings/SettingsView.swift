import SwiftUI

// MARK: - SettingsView
// Apple HIG Compliant Settings Hub

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
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Card Section
                Section {
                    Button {
                        HIGFeedback.impact(.light)
                        showingAccountSheet = true
                    } label: {
                        HStack(spacing: HIGTokens.Spacing.md) {
                            AccountAvatarView(identifier: accountManager.activeEmail, size: 52)
                            
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                HStack(spacing: HIGTokens.Spacing.xs) {
                                    HIGBadge(.custom(color: .orange, text: "Active Account"), isCompact: true)
                                }
                                
                                Text(accountManager.activeEmail.isEmpty ? "No Account Selected" : accountManager.activeEmail)
                                    .font(HIGTypography.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                
                                Text("Tap to switch or add accounts")
                                    .font(HIGTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(HIGTypography.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                // MARK: - Cloudflare Operations & Status
                Section {
                    NavigationLink(destination: CloudflareStatusView()) {
                        HStack(spacing: HIGTokens.Spacing.md) {
                            ListRowIcon(icon: "antenna.radiowaves.left.and.right", color: HIGColors.success)
                            
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                Text("System Status")
                                    .font(HIGTypography.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Live Cloudflare network & service health")
                                    .font(HIGTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                    }
                    
                    NavigationLink(destination: AuditLogsView()) {
                        HStack(spacing: HIGTokens.Spacing.md) {
                            ListRowIcon(icon: "list.bullet.rectangle.portrait.fill", color: .blue)
                            
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                Text("Audit Logs")
                                    .font(HIGTypography.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Account change history & actor records")
                                    .font(HIGTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                                icon: "faceid",
                                color: HIGColors.success,
                                title: "App Lock"
                            )
                            
                            Spacer()
                            
                            Text(isAppLockEnabled ? "On" : "Off")
                                .font(HIGTypography.subheadline)
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
                        HIGFeedback.impact(.light)
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
                            Text(themeManager.currentColor.displayName)
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.secondary)
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
                                .font(HIGTypography.subheadline)
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
                        HIGFeedback.selection()
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
                            HIGFeedback.impact(.medium)
                        }
                    }
                    
                    Button {
                        HIGFeedback.impact(.medium)
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
                                    .font(HIGTypography.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Preferences")
                }
                
                // MARK: - Support & Design System
                Section {
                    NavigationLink(destination: DesignSystemGalleryView()) {
                        SettingsRowView(
                            icon: "square.stack.3d.up.fill",
                            color: Color.higAccent,
                            title: "Design System Showcase"
                        )
                    }
                    
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
                        HIGFeedback.impact(.medium)
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
        
        return VStack(spacing: HIGTokens.Spacing.xxs) {
            Text("Cloudns v\(appVersion) (\(buildNumber))")
                .font(HIGTypography.caption)
                .foregroundStyle(.secondary)
            
            Text("Designed for Cloudflare Edge & Zero Trust")
                .font(HIGTypography.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, HIGTokens.Spacing.md)
        .padding(.bottom, HIGTokens.Spacing.sm)
    }
}

// MARK: - SettingsRowView (Inlined & Cohesive)

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
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: icon, color: color)
            
            Text(title)
                .font(HIGTypography.body.weight(.medium))
                .foregroundStyle(.primary)
        }
    }
}
