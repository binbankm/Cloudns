import SwiftUI

// MARK: - ScrapeShieldView

struct ScrapeShieldView: View {
    let zoneId: String
    
    @StateObject private var viewModel = ScrapeShieldViewModel()
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: 12) {
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
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.purple)
                    }
                    .padding(.top, 4)
                    
                    Text("Scrape Shield")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Protect your content from scrapers, hotlinkers, and email harvesters.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
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
                        Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "email_obfuscation", value: val ? "on" : "off") }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "envelope.badge.shield.half.filled.fill", color: .blue, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Email Obfuscation")
                                .font(.body)
                            Text("Hides plaintext email addresses from automated bots.")
                                .font(.caption)
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
                        Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "server_side_excludes", value: val ? "on" : "off") }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "server.rack", color: .orange, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Server-Side Excludes")
                                .font(.body)
                            Text("Hides sensitive HTML markup tags from suspicious visitors.")
                                .font(.caption)
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
                        Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "hotlink_protection", value: val ? "on" : "off") }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "photo.fill", color: .red, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Hotlink Protection")
                                .font(.body)
                            Text("Prevents external websites from embedding your images.")
                                .font(.caption)
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
