import SwiftUI

// MARK: - SSLSettingsView
// Apple HIG Compliant Cloudflare SSL/TLS Encryption, Edge Certificates & HSTS

struct SSLSettingsView: View {
    let zoneId: String
    @StateObject private var viewModel = SSLSettingsViewModel()
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: HIGTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [HIGColors.success.opacity(0.18), Color.teal.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(HIGTypography.title2.weight(.semibold))
                            .foregroundStyle(HIGColors.success)
                    }
                    .padding(.top, HIGTokens.Spacing.xs)
                    
                    Text("SSL / TLS Encryption")
                        .font(HIGTypography.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Manage end-to-end encryption, edge certificates, and security protocols.")
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
            
            // MARK: - Encryption Mode
            Section(
                header: Text("SSL/TLS Encryption Mode"),
                footer: Text("Full or Full (Strict) is recommended if your origin server has an active SSL certificate.")
            ) {
                HStack(spacing: HIGTokens.Spacing.md) {
                    ListRowIcon(icon: "lock.fill", color: HIGColors.success)
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        Text("Encryption Mode")
                            .font(HIGTypography.body)
                        Text(modeDescription(viewModel.sslMode))
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Encryption Mode", selection: Binding(
                        get: { viewModel.sslMode },
                        set: { newValue in
                            guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                            HIGFeedback.selection()
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
                        HIGFeedback.selection()
                        Task {
                            await viewModel.updateAlwaysUseHTTPS(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess("Always Use HTTPS Updated", icon: "arrow.triangle.swap")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "arrow.triangle.swap", color: .blue)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Always Use HTTPS")
                                .font(HIGTypography.body)
                            Text("Redirect all HTTP requests to HTTPS automatically.")
                                .font(HIGTypography.caption)
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
                        HIGFeedback.selection()
                        Task {
                            await viewModel.updateAutomaticHTTPSRewrites(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess("Automatic HTTPS Rewrites Updated", icon: "arrow.counterclockwise.circle.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "arrow.counterclockwise.circle.fill", color: .teal)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Automatic HTTPS Rewrites")
                                .font(HIGTypography.body)
                            Text("Rewrite insecure HTTP URLs in HTML to secure HTTPS.")
                                .font(HIGTypography.caption)
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
                HStack(spacing: HIGTokens.Spacing.md) {
                    ListRowIcon(icon: "shield.lefthalf.filled", color: .indigo)
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        Text("Minimum TLS Version")
                            .font(HIGTypography.body)
                        Text("Only allow HTTPS connections using this TLS version or higher.")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Minimum TLS Version", selection: Binding(
                        get: { viewModel.minTLSVersion },
                        set: { newValue in
                            guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                            HIGFeedback.selection()
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
                        HIGFeedback.selection()
                        Task {
                            await viewModel.updateTLS13(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess("TLS 1.3 Updated", icon: "bolt.shield.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "bolt.shield.fill", color: .purple)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            HStack(spacing: HIGTokens.Spacing.xs) {
                                Text("TLS 1.3")
                                    .font(HIGTypography.body)
                                HIGBadge(.active("Fast 1-RTT"), isCompact: true)
                            }
                            Text("Fastest and most modern TLS connection handshake protocol.")
                                .font(HIGTypography.caption)
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
                        HIGFeedback.selection()
                        Task {
                            await viewModel.updateOpportunisticEncryption(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess("Opportunistic Encryption Updated", icon: "key.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "key.fill", color: .orange)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Opportunistic Encryption")
                                .font(HIGTypography.body)
                            Text("Allows browsers to access HTTP URIs over an encrypted TLS channel.")
                                .font(HIGTypography.caption)
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
                        if enabled { HIGFeedback.warning() } else { HIGFeedback.selection() }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "checkmark.seal.fill", color: viewModel.hstsEnabled ? HIGColors.error : .gray)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Enable HSTS")
                                .font(HIGTypography.body)
                            Text("HTTP Strict Transport Security")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                if viewModel.hstsEnabled {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "clock.fill", color: .indigo)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Max-Age")
                                .font(HIGTypography.body)
                            Text("Duration browser enforces HTTPS.")
                                .font(HIGTypography.caption)
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
                            .font(HIGTypography.body)
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    Toggle(isOn: $viewModel.hstsNoSniff) {
                        Text("No-Sniff Header")
                            .font(HIGTypography.body)
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    Toggle(isOn: $viewModel.hstsPreload) {
                        Text("Preload Approval")
                            .font(HIGTypography.body)
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    Button("Save HSTS Settings") {
                        HIGFeedback.impact(.medium)
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
                    .higTouchTarget(44)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("SSL/TLS")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading SSL/TLS Settings…"))
            }
        }
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
