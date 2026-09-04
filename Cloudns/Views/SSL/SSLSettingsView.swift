import SwiftUI

// MARK: - SSLSettingsView
// Apple HIG Compliant Cloudflare SSL/TLS Encryption, Edge Certificates & HSTS (iOS 16.0+)

struct SSLSettingsView: View {
    let zoneId: String
    @StateObject private var viewModel = SSLSettingsViewModel()
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.18), Color.teal.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 4)
                    
                    Text("SSL / TLS Encryption")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Manage end-to-end encryption, edge certificates, and security protocols.")
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
            
            // MARK: - Encryption Mode
            Section(
                header: Text("SSL/TLS Encryption Mode"),
                footer: Text("Full or Full (Strict) is recommended if your origin server has an active SSL certificate.")
            ) {
                HStack(spacing: 12) {
                    ListRowIcon(icon: "lock.fill", color: .green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Encryption Mode")
                            .font(.body)
                        Text(modeDescription(viewModel.sslMode))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Encryption Mode", selection: Binding(
                        get: { viewModel.sslMode },
                        set: { newValue in
                            guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                            HapticManager.selection()
                            Task {
                                await viewModel.updateSSLMode(zoneId: zoneId, mode: newValue)
                                ToastManager.shared.showSuccess("SSL Mode Updated", icon: "lock.fill")
                            }
                        }
                    )) {
                        Text("Off").tag("off")
                        Text("Flexible").tag("flexible")
                        Text("Full").tag("full")
                        Text("Full (Strict)").tag("strict")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Edge Certificates
            Section(
                header: Text("Edge Certificates"),
                footer: Text("Redirect all incoming HTTP requests to HTTPS and prevent mixed content warnings.")
            ) {
                // Always Use HTTPS
                Toggle(isOn: Binding(
                    get: { viewModel.alwaysUseHTTPS },
                    set: { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HapticManager.selection()
                        Task {
                            await viewModel.updateAlwaysUseHTTPS(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess("Always Use HTTPS Updated", icon: "arrow.triangle.swap")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "arrow.triangle.swap", color: .blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Always Use HTTPS")
                                .font(.body)
                            Text("Redirect all HTTP requests to HTTPS automatically.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Automatic HTTPS Rewrites
                Toggle(isOn: Binding(
                    get: { viewModel.automaticHTTPSRewrites },
                    set: { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HapticManager.selection()
                        Task {
                            await viewModel.updateAutomaticHTTPSRewrites(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess("Automatic HTTPS Rewrites Updated", icon: "arrow.counterclockwise.circle.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "arrow.counterclockwise.circle.fill", color: .teal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Automatic HTTPS Rewrites")
                                .font(.body)
                            Text("Rewrite insecure HTTP URLs in HTML to secure HTTPS.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Advanced SSL/TLS
            Section(
                header: Text("Advanced SSL/TLS Settings"),
                footer: Text("Configure minimum TLS cipher versions and privacy routing features.")
            ) {
                // Min TLS Version
                HStack(spacing: 12) {
                    ListRowIcon(icon: "shield.lefthalf.filled", color: .indigo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Minimum TLS Version")
                            .font(.body)
                        Text("Only allow HTTPS connections using this TLS version or higher.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Minimum TLS Version", selection: Binding(
                        get: { viewModel.minTLSVersion },
                        set: { newValue in
                            guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                            HapticManager.selection()
                            Task {
                                await viewModel.updateMinTLSVersion(zoneId: zoneId, version: newValue)
                                ToastManager.shared.showSuccess("Minimum TLS Version Updated", icon: "shield.lefthalf.filled")
                            }
                        }
                    )) {
                        Text("TLS 1.0").tag("1.0")
                        Text("TLS 1.1").tag("1.1")
                        Text("TLS 1.2").tag("1.2")
                        Text("TLS 1.3").tag("1.3")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .disabled(!viewModel.hasFetchedData)
                
                // TLS 1.3
                Toggle(isOn: Binding(
                    get: { viewModel.tls13 },
                    set: { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HapticManager.selection()
                        Task {
                            await viewModel.updateTLS13(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess("TLS 1.3 Updated", icon: "bolt.shield.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "bolt.shield.fill", color: .purple)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("TLS 1.3")
                                    .font(.body)
                                Text("Fast 1-RTT")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.14))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                            Text("Fastest and most modern TLS connection handshake protocol.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Opportunistic Encryption
                Toggle(isOn: Binding(
                    get: { viewModel.opportunisticEncryption },
                    set: { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HapticManager.selection()
                        Task {
                            await viewModel.updateOpportunisticEncryption(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess("Opportunistic Encryption Updated", icon: "key.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "key.fill", color: .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Opportunistic Encryption")
                                .font(.body)
                            Text("Allows browsers to access HTTP URIs over an encrypted TLS channel.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - HSTS
            Section(
                header: Text("HSTS (Strict Transport Security)"),
                footer: Text("Enforcing HSTS tells browsers to never load your site over plain HTTP.")
            ) {
                Toggle(isOn: Binding(
                    get: { viewModel.hstsEnabled },
                    set: { enabled in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        viewModel.hstsEnabled = enabled
                        if enabled { HapticManager.notification(.warning) } else { HapticManager.selection() }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "checkmark.seal.fill", color: viewModel.hstsEnabled ? .red : .gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable HSTS")
                                .font(.body)
                            Text("HTTP Strict Transport Security")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                if viewModel.hstsEnabled {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "clock.fill", color: .indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Max-Age")
                                .font(.body)
                            Text("Duration browser enforces HTTPS.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("Max-Age", selection: $viewModel.hstsMaxAge) {
                            Text("1 Month").tag(2592000)
                            Text("3 Months").tag(7776000)
                            Text("6 Months").tag(15552000)
                            Text("12 Months").tag(31536000)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    Toggle(isOn: $viewModel.hstsIncludeSubdomains) {
                        Text("Include Subdomains")
                            .font(.body)
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    Toggle(isOn: $viewModel.hstsNoSniff) {
                        Text("No-Sniff Header")
                            .font(.body)
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    Toggle(isOn: $viewModel.hstsPreload) {
                        Text("Preload Approval")
                            .font(.body)
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    Button("Save HSTS Settings") {
                        HapticManager.impact(.medium)
                        Task {
                            await viewModel.updateHSTS(
                                zoneId: zoneId,
                                enabled: viewModel.hstsEnabled,
                                maxAge: viewModel.hstsMaxAge,
                                subdomains: viewModel.hstsIncludeSubdomains,
                                nosniff: viewModel.hstsNoSniff,
                                preload: viewModel.hstsPreload
                            )
                            ToastManager.shared.showSuccess("HSTS Settings Saved", icon: "checkmark.seal.fill")
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("SSL/TLS")
        .navigationBarTitleDisplayMode(.inline)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading SSL/TLS Settings…"
        )
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            if let errorMsg = viewModel.errorMessage {
                Text(verbatim: errorMsg)
            }
        })
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
    }
    
    private func modeDescription(_ mode: String) -> LocalizedStringKey {
        switch mode {
        case "off": return "No encryption between visitor and origin."
        case "flexible": return "Encrypted to edge, plain HTTP to origin."
        case "full": return "Encrypted end-to-end (self-signed allowed)."
        case "strict": return "Encrypted end-to-end with verified CA cert."
        default: return "Configuring…"
        }
    }
}
