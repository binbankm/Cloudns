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
        List {
            if viewModel.isLoading && viewModel.dnssec == nil {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.dnssec == nil {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchDNSSEC() }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else if let dnssec = viewModel.dnssec {
                // Header Status Section
                Section(footer: 
                    Text("Protect your domain from DNS spoofing and cache poisoning by enabling DNSSEC and adding the DS record to your domain registrar.")
                ) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(statusColor(for: dnssec.status))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DNSSEC Status")
                                .font(.body)
                            Text(dnssec.status.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(statusColor(for: dnssec.status))
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Toggle(isOn: Binding(
                        get: { dnssec.status == "active" || dnssec.status == "pending" },
                        set: { _ in Task { await viewModel.toggleDNSSEC() } }
                    )) {
                        Text(dnssec.status == "active" ? "Enabled" : "Enable DNSSEC")
                            .font(.body)
                    }
                }
                
                // DS Records Section (if active/pending)
                if dnssec.status == "active" || dnssec.status == "pending" {
                    Section(header: Text("DS Record (Registrar Configuration)")) {
                        DetailRow(title: "DS Record", value: dnssec.ds)
                        DetailRow(title: "Digest", value: dnssec.digest)
                        DetailRow(title: "Digest Type", value: dnssec.digest_type)
                        DetailRow(title: "Algorithm", value: dnssec.algorithm)
                        DetailRow(title: "Key Tag", value: dnssec.key_tag.map(String.init))
                        DetailRow(title: "Flags", value: dnssec.flags.map(String.init))
                        DetailRow(title: "Public Key", value: dnssec.public_key, isLast: true)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.fetchDNSSEC()
        }
        .navigationTitle("DNSSEC")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchDNSSEC()
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
}

struct DetailRow: View {
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
                
                Button(action: {
                    UIPasteboard.general.string = validValue
                    let localizedTitle = NSLocalizedString(title, comment: "")
                    let copyFormat = NSLocalizedString("%@ copied", comment: "")
                    ToastManager.shared.showCopied(String(format: copyFormat, localizedTitle))
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("复制\(title)")
            }
        }
    }
}
