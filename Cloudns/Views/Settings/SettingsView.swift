import SwiftUI

struct SettingsView: View {
    @AppStorage(AppStorageKey.isAppLockEnabled) private var isAppLockEnabled = false
    @AppStorage(AppStorageKey.themePreference) private var themePreference = "system"
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    @AppStorage(AppStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(AppStorageKey.isLoggedIn) private var isLoggedIn = false
    @Environment(\.openURL) private var openURL
    
    @State private var showingLogoutAlert = false
    @State private var showingClearCacheAlert = false
    @ObservedObject private var accountManager = AccountManager.shared
    @ObservedObject private var cacheManager = CacheManager.shared
    @ObservedObject private var iconManager = AppIconManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Card Section
                Section {
                    NavigationLink(destination: AccountsView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 54, height: 54)
                                    .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
                                
                                Text(accountManager.activeEmail.prefix(1).uppercased())
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                            .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    HIGBadge(.custom(color: .orange, text: "Active Account"), isCompact: true)
                                }
                                
                                Text(accountManager.activeEmail.isEmpty ? "No Account Selected" : accountManager.activeEmail)
                                    .font(.body.weight(.medium))
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
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "antenna.radiowaves.left.and.right", color: .green, size: 28, cornerRadius: 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("System Status")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text("Live Cloudflare network & service health")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    
                    NavigationLink(destination: AuditLogsView(accountId: "")) {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "list.bullet.rectangle.portrait.fill", color: .blue, size: 28, cornerRadius: 6)
                            
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
                    NavigationLink {
                        AppLockSettingsView()
                    } label: {
                        HStack {
                            SettingsRowView(
                                icon: "faceid",
                                color: .green,
                                title: "App Lock"
                            )
                            
                            Spacer()
                            
                            Text(isAppLockEnabled ? "On" : "Off")
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
                        HIGFeedback.impact(.light)
                    }
                    
                    NavigationLink(destination: AppIconPickerView()) {
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
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
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
                Section {
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
            .alert("Clear Local Cache", isPresented: $showingClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    Task {
                        await cacheManager.clearAllCaches()
                        HIGFeedback.success()
                    }
                }
            } message: {
                Text("Are you sure you want to clear cached network responses and temporary storage?")
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    AccountManager.shared.logoutAll()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to log out of your Cloudflare account?")
            }
        }
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
        HStack(spacing: 12) {
            ListRowIcon(icon: icon, color: color, size: 28, cornerRadius: 6)
            
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

