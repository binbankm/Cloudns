import SwiftUI

// MARK: - DNSSECView

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
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.18), Color.indigo.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.blue)
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
                    ListRowIcon(icon: "shield.lefthalf.filled", color: statusColor(for: status), size: 28, cornerRadius: 6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DNSSEC Status")
                            .font(.body)
                        Text(status.capitalized)
                            .font(.caption)
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
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "checkmark.shield.fill", color: .blue, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
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
                            UIPasteboard.general.string = fullConfig
                            ToastManager.shared.showCopied("Configuration Copied")
                        } label: {
                            Label("Copy All", systemImage: "doc.on.doc")
                                .font(.caption.weight(.semibold))
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
                HIGContentState(.loading(message: "Loading DNSSEC Status..."))
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
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(val)
                        .font(.body.monospaced())
                        .foregroundStyle(.primary)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = val
                    ToastManager.shared.showCopied()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Copy")
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
