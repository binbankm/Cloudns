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
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading && viewModel.dnssec == nil {
                List {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, viewModel.dnssec == nil {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchDNSSEC() }
                    }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if let dnssec = viewModel.dnssec {
                List {
                    // Header Status Section
                    Section(footer: 
                        Text("Protect your domain from DNS spoofing and cache poisoning by enabling DNSSEC and adding the DS record to your domain registrar.")
                    ) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 28))
                                .foregroundColor(statusColor(for: dnssec.status))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DNSSEC Status")
                                    .font(.body)
                                Text(dnssec.status.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(statusColor(for: dnssec.status))
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
                        .disabled(viewModel.isLoading)
                    }
                    
                    if dnssec.status == "active" || dnssec.status == "pending" {
                        // Details Section
                        Section(header: Text("DS Record Details")) {
                            DetailRow(title: "DS Record", value: dnssec.ds)
                            DetailRow(title: "Digest", value: dnssec.digest)
                            DetailRow(title: "Digest Type", value: dnssec.digest_type)
                            DetailRow(title: "Digest Algorithm", value: dnssec.digest_algorithm)
                            DetailRow(title: "Algorithm", value: dnssec.algorithm)
                            DetailRow(title: "Public Key", value: dnssec.public_key)
                            DetailRow(title: "Key Tag", value: dnssec.key_tag != nil ? String(dnssec.key_tag!) : nil)
                            DetailRow(title: "Flags", value: dnssec.flags != nil ? String(dnssec.flags!) : nil, isLast: true)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.fetchDNSSEC()
                }
            }
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
                        .foregroundColor(.secondary)
                    Text(validValue)
                        .font(.body.monospacedDigit())
                        .foregroundColor(.primary)
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
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
