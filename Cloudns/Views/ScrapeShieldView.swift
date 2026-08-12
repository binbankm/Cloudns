import SwiftUI

struct ScrapeShieldView: View {
    let zoneId: String
    
    @StateObject private var viewModel = ScrapeShieldViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 52, weight: .light))
                        .foregroundColor(.purple)
                        .padding(.top, 10)
                    
                    Text("Scrape Shield")
                        .font(.title2.bold())
                    
                    Text("Protect your content from scrapers, hotlinkers, and email harvesters.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                }
                
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(10)
                }
                
                // Settings Cards
                VStack(spacing: 0) {
                    
                    // Email Obfuscation
                    ScrapeShieldRow(
                        title: "Email Address Obfuscation",
                        subtitle: "Hides your email addresses from scrapers. Visitors can still see them.",
                        icon: "envelope.badge.shield.half.filled.fill",
                        iconColor: .blue,
                        isOn: Binding(
                            get: { viewModel.emailObfuscationEnabled },
                            set: { val in
                                viewModel.emailObfuscationEnabled = val
                                Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "email_obfuscation", value: val ? "on" : "off") }
                            }
                        ),
                        isLoading: viewModel.isLoading && !viewModel.hasFetchedData
                    )
                    
                    Divider().padding(.leading, 64)
                    
                    // Server Side Excludes
                    ScrapeShieldRow(
                        title: "Server-Side Excludes",
                        subtitle: "Hides specific page content from suspicious visitors.",
                        icon: "server.rack",
                        iconColor: .orange,
                        isOn: Binding(
                            get: { viewModel.serverSideExcludesEnabled },
                            set: { val in
                                viewModel.serverSideExcludesEnabled = val
                                Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "server_side_exclude", value: val ? "on" : "off") }
                            }
                        ),
                        isLoading: viewModel.isLoading && !viewModel.hasFetchedData
                    )
                    
                    Divider().padding(.leading, 64)
                    
                    // Hotlink Protection
                    ScrapeShieldRow(
                        title: "Hotlink Protection",
                        subtitle: "Prevents other sites from embedding your images, saving your bandwidth.",
                        icon: "photo.fill",
                        iconColor: .red,
                        isOn: Binding(
                            get: { viewModel.hotlinkProtectionEnabled },
                            set: { val in
                                viewModel.hotlinkProtectionEnabled = val
                                Task { await viewModel.updateSetting(zoneId: zoneId, settingId: "hotlink_protection", value: val ? "on" : "off") }
                            }
                        ),
                        isLoading: viewModel.isLoading && !viewModel.hasFetchedData
                    )
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                // Info Box
                VStack(alignment: .leading, spacing: 8) {
                    Label("About Scrape Shield", systemImage: "info.circle")
                        .font(.subheadline.bold())
                        .foregroundColor(.purple)
                    
                    Text("These protections help safeguard your content without impacting real visitors. Email obfuscation uses JavaScript to rewrite addresses, while hotlink protection blocks image requests from external domains.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.purple.opacity(0.07))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Scrape Shield")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
    }
}

struct ScrapeShieldRow: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                iconColor.opacity(0.15)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 36, height: 36)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
