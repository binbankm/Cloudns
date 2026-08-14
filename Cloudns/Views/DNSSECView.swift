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
                ProgressView()
                    .scaleEffect(1.5)
            } else if let errorMessage = viewModel.errorMessage, viewModel.dnssec == nil {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await viewModel.fetchDNSSEC() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let dnssec = viewModel.dnssec {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Status Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(statusColor(for: dnssec.status))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DNSSEC Status")
                                        .font(.headline)
                                    Text(dnssec.status.capitalized)
                                        .font(.subheadline.bold())
                                        .foregroundColor(statusColor(for: dnssec.status))
                                }
                                
                                Spacer()
                                
                                if viewModel.isLoading {
                                    ProgressView()
                                }
                            }
                            
                            Text("Protect your domain from DNS spoofing and cache poisoning by enabling DNSSEC and adding the DS record to your domain registrar.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Toggle(isOn: Binding(
                                get: { dnssec.status == "active" || dnssec.status == "pending" },
                                set: { _ in Task { await viewModel.toggleDNSSEC() } }
                            )) {
                                Text(dnssec.status == "active" ? "Enabled" : "Enable DNSSEC")
                                    .font(.body.bold())
                            }
                            .disabled(viewModel.isLoading)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        if dnssec.status == "active" || dnssec.status == "pending" {
                            // Details Card
                            VStack(alignment: .leading, spacing: 0) {
                                Text("DS Record Details")
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                                
                                Divider()
                                
                                DetailRow(title: "DS Record", value: dnssec.ds)
                                DetailRow(title: "Digest", value: dnssec.digest)
                                DetailRow(title: "Digest Type", value: dnssec.digest_type)
                                DetailRow(title: "Digest Algorithm", value: dnssec.digest_algorithm)
                                DetailRow(title: "Algorithm", value: dnssec.algorithm)
                                DetailRow(title: "Public Key", value: dnssec.public_key)
                                DetailRow(title: "Key Tag", value: dnssec.key_tag != nil ? String(dnssec.key_tag!) : nil)
                                DetailRow(title: "Flags", value: dnssec.flags != nil ? String(dnssec.flags!) : nil, isLast: true)
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = validValue
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
                
                Text(validValue)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                
                if !isLast {
                    Divider().padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
