import SwiftUI

// MARK: - DNSSECView
// Apple HIG Compliant DNSSEC Status and DS Record Viewer (iOS 16.0+)

struct DNSSECView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: DNSSECViewModel
    
    private var accentColor: Color {
        ThemeManager.shared.currentColor.color
    }
    
    init(zoneId: String, zoneName: String) {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: DNSSECViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.18), Color.indigo.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "key.horizontal.fill")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(accentColor)
                    }
                    .padding(.top, 4)
                    
                    Text("DNSSEC")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Cryptographically sign DNS records to prevent spoofing for \(zoneName).")
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
            
            // MARK: - Protection Status
            Section(
                header: Text("Status"),
                footer: Text("When enabled, Cloudflare generates DS records to be registered at your domain registrar.")
            ) {
                let status = viewModel.dnssec?.status ?? "disabled"
                
                HStack(spacing: 12) {
                    ListRowIcon(icon: "shield.lefthalf.filled", color: statusColor(for: status))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DNSSEC Status")
                            .font(.body)
                        Text(status.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    statusPill(for: status)
                }
                .disabled(viewModel.dnssec == nil)
                
                Toggle(isOn: Binding(
                    get: { status == "active" || status == "pending" },
                    set: { _ in
                        HapticManager.selection()
                        Task { await viewModel.toggleDNSSEC() }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "checkmark.shield.fill", color: .green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable DNSSEC")
                                .font(.body)
                            Text("Sign zone records with DNSSEC keys.")
                                .font(.caption)
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
                            copyToClipboard(fullConfig, toast: "Configuration Copied")
                        } label: {
                            Label("Copy All", systemImage: "doc.on.doc")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(accentColor)
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
        .listState(
            isLoading: viewModel.dnssec == nil && viewModel.isLoading,
            loadingMessage: "Loading DNSSEC Status…",
            error: viewModel.dnssec == nil ? viewModel.errorMessage : nil,
            onRetry: { Task { await viewModel.fetchDNSSEC() } }
        )
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
    private func statusPill(for status: String) -> some View {
        let isAct = status == "active"
        let isPend = status == "pending"
        let color: Color = isAct ? .green : (isPend ? .orange : .secondary)
        
        Text(status.capitalized)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
    
    @ViewBuilder
    private func dsFieldRow(label: String, value: String?) -> some View {
        if let val = value, !val.isEmpty {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(verbatim: val)
                        .font(.body.monospaced())
                        .foregroundStyle(.primary)
                }
                Spacer()
                Button {
                    copyToClipboard(val, toast: "Copied to Clipboard")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(accentColor)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Copy \(label)")
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "active": return .green
        case "pending": return .orange
        default: return .gray
        }
    }
}
