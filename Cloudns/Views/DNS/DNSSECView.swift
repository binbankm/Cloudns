import SwiftUI

// MARK: - DNSSECView
// Apple HIG Compliant DNSSEC Status and DS Record Viewer

struct DNSSECView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: DNSSECViewModel
    
    init(zoneId: String, zoneName: String) {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: DNSSECViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: HIGTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.higAccent.opacity(0.18), Color.indigo.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "key.horizontal.fill")
                            .font(HIGTypography.title.weight(.semibold))
                            .foregroundStyle(Color.higAccent)
                    }
                    .padding(.top, HIGTokens.Spacing.xs)
                    
                    Text("DNSSEC")
                        .font(HIGTypography.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Cryptographically sign DNS records to prevent spoofing for \(zoneName).")
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HIGTokens.Spacing.lg)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HIGTokens.Spacing.sm)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // MARK: - Protection Status
            Section(
                header: Text("Status"),
                footer: Text("When enabled, Cloudflare generates DS records to be registered at your domain registrar.")
            ) {
                let status = viewModel.dnssec?.status ?? "disabled"
                
                HStack(spacing: HIGTokens.Spacing.md) {
                    ListRowIcon(icon: "shield.lefthalf.filled", color: statusColor(for: status))
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        Text("DNSSEC Status")
                            .font(HIGTypography.body)
                        Text(status.capitalized)
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if status == "active" {
                        HIGBadge(.active, isCompact: true)
                    } else if status == "pending" {
                        HIGBadge(.warning("Pending"), isCompact: true)
                    } else {
                        HIGBadge(.custom(color: .secondary, text: "Disabled"), isCompact: true)
                    }
                }
                .disabled(viewModel.dnssec == nil)
                
                Toggle(isOn: Binding(
                    get: { status == "active" || status == "pending" },
                    set: { _ in
                        HIGFeedback.selection()
                        Task { await viewModel.toggleDNSSEC() }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "checkmark.shield.fill", color: HIGColors.success)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Enable DNSSEC")
                                .font(HIGTypography.body)
                            Text("Sign zone records with DNSSEC keys.")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(viewModel.dnssec == nil)
            }
            
            // MARK: - DS Records (if active/pending)
            if let dnssec = viewModel.dnssec, dnssec.status == "active" || dnssec.status == "pending" {
                Section(
                    header: HStack {
                        Text("DS Record Details")
                        Spacer()
                        Button {
                            let fullConfig = """
                            Zone: \(zoneName)
                            DS Record: \(dnssec.ds ?? "")
                            Digest: \(dnssec.digest ?? "")
                            Digest Type: \(dnssec.digest_type ?? "")
                            Algorithm: \(dnssec.algorithm ?? "")
                            Key Tag: \(dnssec.key_tag.map(String.init) ?? "")
                            Flags: \(dnssec.flags.map(String.init) ?? "")
                            Public Key: \(dnssec.public_key ?? "")
                            """
                            UIPasteboard.general.string = fullConfig
                            ToastManager.shared.showCopied("Configuration Copied")
                            HIGFeedback.copied()
                        } label: {
                            Label("Copy All", systemImage: "doc.on.doc")
                                .font(HIGTypography.caption.weight(.semibold))
                                .foregroundStyle(Color.higAccent)
                        }
                    },
                    footer: Text("Add these DS record details to your domain registrar settings to complete verification.")
                ) {
                    dsFieldRow(label: "DS Record", value: dnssec.ds)
                    dsFieldRow(label: "Digest", value: dnssec.digest)
                    dsFieldRow(label: "Digest Type", value: dnssec.digest_type)
                    dsFieldRow(label: "Algorithm", value: dnssec.algorithm)
                    dsFieldRow(label: "Key Tag", value: dnssec.key_tag.map(String.init))
                    dsFieldRow(label: "Flags", value: dnssec.flags.map(String.init))
                    dsFieldRow(label: "Public Key", value: dnssec.public_key)
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.dnssec == nil && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading DNSSEC Status…"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.dnssec == nil && !viewModel.isLoading {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: { Task { await viewModel.fetchDNSSEC() } }
                    )
                )
            }
        }
        .refreshable {
            await viewModel.fetchDNSSEC()
        }
        .navigationTitle("DNSSEC")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchDNSSEC()
        }
    }
    
    @ViewBuilder
    private func dsFieldRow(label: LocalizedStringKey, value: String?) -> some View {
        if let val = value, !val.isEmpty {
            HStack(spacing: HIGTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                    Text(label)
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                    Text(verbatim: val)
                        .font(HIGTypography.body.monospaced())
                        .foregroundStyle(.primary)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = val
                    ToastManager.shared.showCopied()
                    HIGFeedback.copied()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(Color.higAccent)
                }
                .accessibilityLabel("Copy")
                .buttonStyle(.plain)
                .higTouchTarget(44)
            }
            .padding(.vertical, HIGTokens.Spacing.xxs)
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "active": return HIGColors.success
        case "pending": return HIGColors.warning
        default: return .gray
        }
    }
}
