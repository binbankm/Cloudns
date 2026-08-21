import SwiftUI

struct SSLSettingsView: View {
    let zoneId: String
    @StateObject private var viewModel = SSLSettingsViewModel()
    
    var body: some View {
        Form {
            if viewModel.hasFetchedData {
                Section(header: Text("SSL/TLS Encryption Mode"), footer: Text("Choose the encryption mode for your website. Full or Strict is recommended if your origin server has an SSL certificate.")) {
                    Picker("Encryption Mode", selection: $viewModel.sslMode) {
                        Text("Off (Not Secure)").tag("off")
                        Text("Flexible").tag("flexible")
                        Text("Full").tag("full")
                        Text("Full (Strict)").tag("strict")
                    }
                    .pickerStyle(.menu)
                    .disabled(!viewModel.hasFetchedData)
                    .onChange(of: viewModel.sslMode) { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HapticManager.impact(.light)
                        Task {
                            await viewModel.updateSSLMode(zoneId: zoneId, mode: newValue)
                        }
                    }
                }
                
                Section(header: Text("Edge Certificates"), footer: Text("Redirect all requests with scheme 'http' to 'https'. This applies to all http requests to the zone.")) {
                    Toggle(isOn: $viewModel.alwaysUseHTTPS) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Always Use HTTPS")
                            .font(.body)
                        Text("Redirect all HTTP requests to HTTPS.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.alwaysUseHTTPS) { newValue in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.updateAlwaysUseHTTPS(zoneId: zoneId, isOn: newValue)
                    }
                }
                
                Toggle(isOn: $viewModel.automaticHTTPSRewrites) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Automatic HTTPS Rewrites")
                            .font(.body)
                        Text("Automatically rewrite HTTP resources to HTTPS to avoid mixed content warnings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.automaticHTTPSRewrites) { newValue in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.updateAutomaticHTTPSRewrites(zoneId: zoneId, isOn: newValue)
                    }
                }
            }
            
            Section(header: Text("Advanced SSL/TLS Settings"), footer: Text("Configure TLS versions and opportunistic encryption features for legacy or specialized clients.")) {
                Picker("Minimum TLS Version", selection: $viewModel.minTLSVersion) {
                    Text("TLS 1.0").tag("1.0")
                    Text("TLS 1.1").tag("1.1")
                    Text("TLS 1.2").tag("1.2")
                    Text("TLS 1.3").tag("1.3")
                }
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.minTLSVersion) { newValue in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.updateMinTLSVersion(zoneId: zoneId, version: newValue)
                    }
                }
                
                Toggle(isOn: $viewModel.tls13) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TLS 1.3")
                            .font(.body)
                        Text("Enable the latest version of the TLS protocol for improved security and performance.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.tls13) { newValue in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.updateTLS13(zoneId: zoneId, isOn: newValue)
                    }
                }
                
                Toggle(isOn: $viewModel.opportunisticEncryption) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opportunistic Encryption")
                            .font(.body)
                        Text("Allows browsers to access HTTP URIs over an encrypted TLS channel.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.opportunisticEncryption) { newValue in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.updateOpportunisticEncryption(zoneId: zoneId, isOn: newValue)
                    }
                }
                
                Toggle(isOn: $viewModel.opportunisticOnion) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opportunistic Onion")
                            .font(.body)
                        Text("Route Tor users through the Cloudflare Onion service to improve privacy.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.opportunisticOnion) { newValue in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.updateOpportunisticOnion(zoneId: zoneId, isOn: newValue)
                    }
                }
            }
            
            Section(header: Text("HSTS (Strict Transport Security)"), footer: Text("DANGER: Enabling HSTS will force browsers to connect via HTTPS only. If your origin server loses HTTPS support, your site will be inaccessible until the Max-Age expires.")) {
                Toggle(isOn: $viewModel.hstsEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable HSTS")
                            .font(.body)
                            .foregroundStyle(viewModel.hstsEnabled ? .red : .primary)
                        Text("Strict Transport Security (HSTS)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .tint(.red)
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.hstsEnabled) { enabled in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    if enabled {
                        HapticManager.notification(.warning)
                    } else {
                        HapticManager.impact(.light)
                    }
                }
                
                if viewModel.hstsEnabled {
                    Picker("Max-Age (Seconds)", selection: $viewModel.hstsMaxAge) {
                        Text("1 Month (2592000)").tag(2592000)
                        Text("3 Months (7776000)").tag(7776000)
                        Text("6 Months (15552000)").tag(15552000)
                        Text("12 Months (31536000)").tag(31536000)
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    Toggle("Include Subdomains", isOn: $viewModel.hstsIncludeSubdomains)
                        .disabled(!viewModel.hasFetchedData)
                    Toggle("No-Sniff", isOn: $viewModel.hstsNoSniff)
                        .disabled(!viewModel.hasFetchedData)
                    Toggle("Preload (HSTS Preload List)", isOn: $viewModel.hstsPreload)
                        .disabled(!viewModel.hasFetchedData)
                    
                    Button("Save HSTS Configuration") {
                        HapticManager.impact(.medium)
                        Task {
                            await viewModel.updateHSTS(zoneId: zoneId, enabled: viewModel.hstsEnabled, maxAge: viewModel.hstsMaxAge, subdomains: viewModel.hstsIncludeSubdomains, nosniff: viewModel.hstsNoSniff, preload: viewModel.hstsPreload)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                    .foregroundStyle(.blue)
                } else {
                    Button("Save HSTS (Disable)") {
                        HapticManager.impact(.medium)
                        Task {
                            await viewModel.updateHSTS(zoneId: zoneId, enabled: false, maxAge: 0, subdomains: false, nosniff: false, preload: false)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                    .foregroundStyle(.blue)
                }
            }
        } else if viewModel.isLoading {
            Section(header: Text("SSL/TLS Encryption Mode")) {
                    Picker("Encryption Mode", selection: .constant("full")) {
                        Text("Full").tag("full")
                    }
                    .skeletonLoading(true)
                }
                
                Section(header: Text("Edge Certificates")) {
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Always Use HTTPS")
                            Text("Redirect all HTTP requests to HTTPS.")
                        }
                    }
                    .skeletonLoading(true)
                    
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Automatic HTTPS Rewrites")
                            Text("Automatically rewrite HTTP resources to HTTPS.")
                        }
                    }
                    .skeletonLoading(true)
                }
            }
        }
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("SSL/TLS")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
    }
}
