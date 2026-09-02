import SwiftUI

// MARK: - ScrapeShieldView
// Apple HIG Compliant Cloudflare Content Scrape Shield & Obfuscation Settings

struct ScrapeShieldView: View {
    let zoneId: String
    
    @StateObject private var viewModel = ScrapeShieldViewModel()
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: HIGTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.18), Color.pink.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "eye.slash.fill")
                            .font(HIGTypography.title2.weight(.semibold))
                            .foregroundStyle(.purple)
                    }
                    .padding(.top, HIGTokens.Spacing.xs)
                    
                    Text("Scrape Shield")
                        .font(HIGTypography.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Protect your content from scrapers, hotlinkers, and email harvesters.")
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HIGTokens.Spacing.md)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HIGTokens.Spacing.sm)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // MARK: - Protections
            Section(
                header: Text("Content Protections"),
                footer: Text("These protections safeguard your site without impacting legitimate visitors. Email obfuscation prevents scraping, while hotlink protection blocks external image stealing.")
            ) {
                // Email Obfuscation
                Toggle(isOn: Binding(
                    get: { viewModel.emailObfuscationEnabled },
                    set: { val in
                        HIGFeedback.selection()
                        viewModel.emailObfuscationEnabled = val
                        Task {
                            await viewModel.updateSetting(zoneId: zoneId, settingId: "email_obfuscation", value: val ? "on" : "off")
                            ToastManager.shared.showSuccess("Email Obfuscation Updated", icon: "envelope.badge.shield.half.filled.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "envelope.badge.shield.half.filled.fill", color: .blue)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Email Obfuscation")
                                .font(HIGTypography.body)
                            Text("Hides plaintext email addresses from automated bots.")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Server-Side Excludes
                Toggle(isOn: Binding(
                    get: { viewModel.serverSideExcludesEnabled },
                    set: { val in
                        HIGFeedback.selection()
                        viewModel.serverSideExcludesEnabled = val
                        Task {
                            await viewModel.updateSetting(zoneId: zoneId, settingId: "server_side_excludes", value: val ? "on" : "off")
                            ToastManager.shared.showSuccess("Server-Side Excludes Updated", icon: "server.rack")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "server.rack", color: .orange)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Server-Side Excludes")
                                .font(HIGTypography.body)
                            Text("Hides sensitive HTML markup tags from suspicious visitors.")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Hotlink Protection
                Toggle(isOn: Binding(
                    get: { viewModel.hotlinkProtectionEnabled },
                    set: { val in
                        HIGFeedback.selection()
                        viewModel.hotlinkProtectionEnabled = val
                        Task {
                            await viewModel.updateSetting(zoneId: zoneId, settingId: "hotlink_protection", value: val ? "on" : "off")
                            ToastManager.shared.showSuccess("Hotlink Protection Updated", icon: "photo.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "photo.fill", color: HIGColors.error)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Hotlink Protection")
                                .font(HIGTypography.body)
                            Text("Prevents external websites from embedding your images.")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Scrape Shield Settings…"))
            }
        }
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .navigationTitle("Scrape Shield")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
    }
}
