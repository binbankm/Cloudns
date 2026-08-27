import SwiftUI

struct ScrapeShieldView: View {
    // MARK: - Properties
    let zoneId: String
    
    @StateObject private var viewModel = ScrapeShieldViewModel()
    
    // MARK: - Body
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
                    // Email Obfuscation
                    ScrapeShieldRowView(
                        title: "Email Address Obfuscation",
                        subtitle: "Hides your email addresses from scrapers. Visitors can still see them.",
                        icon: "envelope.badge.shield.half.filled.fill",
                        iconColor: .blue,
                        isOn: Binding(
                            get: { viewModel.emailObfuscationEnabled },
                            set: { val in
                                HapticManager.impact(.light)
                                viewModel.emailObfuscationEnabled = val
                                Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "email_obfuscation", value: val ? "on" : "off") }
                            }
                        ),
                        isLoading: viewModel.isLoading && !viewModel.hasFetchedData
                    )
                    
                    // Server-Side Excludes
                    ScrapeShieldRowView(
                        title: "Server-Side Excludes",
                        subtitle: "Hides specific page content from suspicious visitors.",
                        icon: "server.rack",
                        iconColor: .orange,
                        isOn: Binding(
                            get: { viewModel.serverSideExcludesEnabled },
                            set: { val in
                                HapticManager.impact(.light)
                                viewModel.serverSideExcludesEnabled = val
                                Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "server_side_excludes", value: val ? "on" : "off") }
                            }
                        ),
                        isLoading: viewModel.isLoading && !viewModel.hasFetchedData
                    )
                    
                    // Hotlink Protection
                    ScrapeShieldRowView(
                        title: "Hotlink Protection",
                        subtitle: "Prevents other sites from embedding your images, saving your bandwidth.",
                        icon: "photo.fill",
                        iconColor: .red,
                        isOn: Binding(
                            get: { viewModel.hotlinkProtectionEnabled },
                            set: { val in
                                HapticManager.impact(.light)
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
                            iconColor: .purple,
                            isOn: .constant(true),
                            isLoading: true
                        )
                        .skeletonLoading(true)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData && !viewModel.isLoading {
                CloudnsStateOverlayView(
                    state: .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: { Task { await viewModel.fetchSettings(zoneId: zoneId) } }
                    )
                )
            }
        }
        .navigationTitle("Scrape Shield")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
    }
}
