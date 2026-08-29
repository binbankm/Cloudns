import SwiftUI

// MARK: - ScrapeShieldView

struct ScrapeShieldView: View {
    let zoneId: String
    
    @StateObject private var viewModel = ScrapeShieldViewModel()
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.purple)
                        .padding(.top, 10)
                        .accessibilityHidden(true)
                    
                    Text("Scrape Shield")
                        .font(.title2.weight(.semibold))
                    
                    Text("Protect your content from scrapers, hotlinkers, and email harvesters.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            
            if viewModel.hasFetchedData {
                Section(footer: 
                    VStack(alignment: .leading, spacing: 8) {
                        Label("About Scrape Shield", systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                        
                        Text("These protections help safeguard your content without impacting real visitors. Email obfuscation uses JavaScript to rewrite addresses, while hotlink protection blocks image requests from external domains.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                ) {
                    ScrapeShieldRowView(
                        title: "Email Address Obfuscation",
                        subtitle: "Hides your email addresses from scrapers. Visitors can still see them.",
                        icon: "envelope.badge.shield.half.filled.fill",
                        iconColor: .blue,
                        isOn: Binding(
                            get: { viewModel.emailObfuscationEnabled },
                            set: { val in
                                HIGFeedback.selection()
                                viewModel.emailObfuscationEnabled = val
                                Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "email_obfuscation", value: val ? "on" : "off") }
                            }
                        ),
                        isLoading: viewModel.isLoading && !viewModel.hasFetchedData
                    )
                    
                    ScrapeShieldRowView(
                        title: "Server-Side Excludes",
                        subtitle: "Hides specific page content from suspicious visitors.",
                        icon: "server.rack",
                        iconColor: .orange,
                        isOn: Binding(
                            get: { viewModel.serverSideExcludesEnabled },
                            set: { val in
                                HIGFeedback.selection()
                                viewModel.serverSideExcludesEnabled = val
                                Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "server_side_excludes", value: val ? "on" : "off") }
                            }
                        ),
                        isLoading: viewModel.isLoading && !viewModel.hasFetchedData
                    )
                    
                    ScrapeShieldRowView(
                        title: "Hotlink Protection",
                        subtitle: "Prevents other sites from embedding your images, saving your bandwidth.",
                        icon: "photo.fill",
                        iconColor: .red,
                        isOn: Binding(
                            get: { viewModel.hotlinkProtectionEnabled },
                            set: { val in
                                HIGFeedback.selection()
                                viewModel.hotlinkProtectionEnabled = val
                                Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "hotlink_protection", value: val ? "on" : "off") }
                            }
                        ),
                        isLoading: viewModel.isLoading && !viewModel.hasFetchedData
                    )
                }
            } else if viewModel.isLoading {
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        ScrapeShieldRowView(
                            title: "Scrape Protection Setting",
                            subtitle: "Configuring security level and scraper prevention rules...",
                            icon: "shield.fill",
                            iconColor: .gray,
                            isOn: .constant(false),
                            isLoading: true
                        )
                    }
                }
                .redacted(reason: .placeholder)
            }
        }
        .listStyle(.insetGrouped)
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

// MARK: - ScrapeShieldRowView (Inlined & Cohesive)

struct ScrapeShieldRowView: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle(isOn: $isOn) { }
                .labelsHidden()
                .disabled(isLoading)
        }
        .padding(.vertical, 4)
    }
}
