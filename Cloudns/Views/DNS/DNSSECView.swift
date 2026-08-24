import SwiftUI

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
                        loadingSkeletonView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .refreshable {
                HapticManager.impact(.light)
                await viewModel.fetchDNSSEC()
            }
        }
        .overlay {
            if let errorMessage = viewModel.errorMessage, viewModel.dnssec == nil && !viewModel.isLoading {
                StateOverlayView(
                    state: .error(
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
                
                CloudnsBadge(
                    dnssec.status == "active" ? .active("Active") : (dnssec.status == "pending" ? .warning("Pending") : .custom(color: .secondary, text: dnssec.status.capitalized)),
                    isCompact: false
                )
            }
            
            Divider()
            
            Toggle(isOn: Binding(
                get: { dnssec.status == "active" || dnssec.status == "pending" },
                set: { _ in
                    HapticManager.impact(.light)
                    Task { await viewModel.toggleDNSSEC() }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dnssec.status == "active" ? "DNSSEC is Enabled" : "Enable DNSSEC")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("Cryptographically sign DNS lookup responses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 1)
                Text("Protects your domain against DNS cache poisoning and man-in-the-middle spoofing by verifying cryptographic signatures with your registrar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            .padding(10)
            .background(Color.blue.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 2. DS Record Configuration Card
    @ViewBuilder
    private func dsRecordCard(_ dnssec: DNSSEC) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DS Record Configuration")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Add these records to your domain registrar (GoDaddy, Namecheap, etc.)")
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
                    HapticManager.notification(.success)
                    ToastManager.shared.showCopied("All DS fields copied")
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
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 3. Skeleton Loading View
    @ViewBuilder
    private var loadingSkeletonView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DNSSEC Protection")
                            .font(.headline)
                        Text(zoneName)
                            .font(.caption)
                    }
                    Spacer()
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 60, height: 22)
                }
                Divider()
                HStack {
                    Text("Enable DNSSEC Status")
                    Spacer()
                    Toggle(isOn: .constant(true)) { EmptyView() }.labelsHidden()
                }
            }
            .padding(16)
            .cloudnsCard(style: .frosted, cornerRadius: 16)
            .skeletonLoading(true)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("DS Record Configuration")
                    .font(.headline)
                Divider()
                ForEach(0..<5, id: \.self) { idx in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(placeholderTitle(for: idx))
                            .font(.caption)
                        Text(placeholderValue(for: idx))
                            .font(.body.monospacedDigit())
                    }
                }
            }
            .padding(16)
            .cloudnsCard(style: .frosted, cornerRadius: 16)
            .skeletonLoading(true)
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "active": return .green
        case "pending": return .orange
        case "disabled": return .gray
        default: return .gray
        }
    }
    
    private func placeholderTitle(for index: Int) -> String {
        let titles = ["DS Record", "Digest", "Digest Type", "Algorithm", "Key Tag", "Flags"]
        return titles[index % titles.count]
    }
    
    private func placeholderValue(for index: Int) -> String {
        let values = [
            "example.com. 3600 IN DS 2371 13 2 4004D79...8F",
            "4004D7981C02844D04C251877995...8F",
            "2 (SHA-256)",
            "13 (ECDSA Curve P-256 with SHA-256)",
            "2371",
            "257 (KSK)"
        ]
        return values[index % values.count]
    }
}
