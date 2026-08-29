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
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    if let dnssec = viewModel.dnssec {
                        statusCard(dnssec)
                        
                        if dnssec.status == "active" || dnssec.status == "pending" {
                            dsRecordCard(dnssec)
                        }
                    } else if viewModel.isLoading {
                        VStack(spacing: 16) {
                            statusCard(DNSSEC.placeholder)
                            dsRecordCard(DNSSEC.placeholder)
                        }
                        .redacted(reason: .placeholder)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable {
                await viewModel.fetchDNSSEC()
            }
        }
        .overlay {
            if let errorMessage = viewModel.errorMessage, viewModel.dnssec == nil && !viewModel.isLoading {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: { Task { await viewModel.fetchDNSSEC() } }
                    )
                )
            }
        }
        .navigationTitle("DNSSEC")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchDNSSEC()
        }
    }
    
    // MARK: - 1. Hero Status Card
    @ViewBuilder
    private func statusCard(_ dnssec: DNSSEC) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor(for: dnssec.status).opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lock.shield.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(statusColor(for: dnssec.status))
                }
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("DNSSEC Protection")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(zoneName)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HIGBadge(
                    dnssec.status == "active" ? .active : (dnssec.status == "pending" ? .warning("Pending") : .custom(color: .secondary, text: dnssec.status.capitalized)),
                    isCompact: false
                )
            }
            
            Divider()
            
            Toggle(isOn: Binding(
                get: { dnssec.status == "active" || dnssec.status == "pending" },
                set: { _ in
                    HIGFeedback.selection()
                    Task { await viewModel.toggleDNSSEC() }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable DNSSEC")
                        .font(.subheadline.weight(.semibold))
                    Text("Cryptographically sign DNS records to prevent DNS spoofing and cache poisoning.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(viewModel.isLoading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - 2. DS Record Configuration Card
    @ViewBuilder
    private func dsRecordCard(_ dnssec: DNSSEC) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DS Record Details")
                        .font(.headline)
                    Text("Add this DS record to your domain registrar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
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
                    ToastManager.shared.showCopied("DNSSEC Configuration Copied")
                } label: {
                    Label("Copy All", systemImage: "doc.on.doc")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Divider()
            
            VStack(spacing: 10) {
                DNSSECDetailRowView(title: "DS Record", value: dnssec.ds)
                DNSSECDetailRowView(title: "Digest", value: dnssec.digest)
                DNSSECDetailRowView(title: "Digest Type", value: dnssec.digest_type)
                DNSSECDetailRowView(title: "Algorithm", value: dnssec.algorithm)
                DNSSECDetailRowView(title: "Key Tag", value: dnssec.key_tag.map(String.init))
                DNSSECDetailRowView(title: "Flags", value: dnssec.flags.map(String.init))
                DNSSECDetailRowView(title: "Public Key", value: dnssec.public_key, isLast: true)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "active": return .green
        case "pending": return .orange
        case "disabled": return .gray
        default: return .gray
        }
    }
}

// MARK: - DNSSECDetailRowView (Inlined & Cohesive)

struct DNSSECDetailRowView: View {
    let title: String
    let value: String?
    var isLast: Bool = false
    
    var body: some View {
        if let validValue = value, !validValue.isEmpty {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(title))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(validValue)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = validValue
                    ToastManager.shared.showCopied("\(title) Copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Copy \(title)")
            }
        }
    }
}
