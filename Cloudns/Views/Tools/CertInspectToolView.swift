import SwiftUI

struct CertInspectToolView: View {
    @StateObject private var viewModel = SSLCertInspectorViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // 1. Search / Input Section
            Section(header: Text("Host / Domain"), footer: Text("Inspects remote SSL/TLS certificate validity, expiration, intermediate trust chain & cryptographic cipher suites.")) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.body)
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    
                    TextField("example.com or hostname", text: $viewModel.domainInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(.body.monospacedDigit())
                        .submitLabel(.search)
                        .onSubmit {
                            performInspect()
                        }
                    
                    if !viewModel.domainInput.isEmpty {
                        Button {
                            viewModel.domainInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear domain input")
                    }
                }
                
                Button {
                    performInspect()
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                        }
                        Text(viewModel.isLoading ? "Inspecting Handshake..." : "Inspect SSL/TLS Certificate")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.certDetails == nil {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Inspecting SSL Certificate...")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } else if let details = viewModel.certDetails {
                // 2. Validity Hero Section
                Section(header: Text("Certificate Validity")) {
                    validityRows(details: details)
                }
                
                // 3. Chain Hierarchy Section
                Section(header: Text("Certificate Chain Hierarchy (\(details.chainNames.count))")) {
                    chainRows(details: details)
                }
                
                // 4. Crypto Parameters Section
                Section(header: Text("Cryptographic Parameters")) {
                    cryptoRows(details: details)
                }
                
                // 5. SANs Domains Section
                Section(header: Text("Subject Alternative Names (\(details.sans.count))")) {
                    sansRows(details: details)
                }
            } else if let error = viewModel.errorMessage {
                Section(header: Text("Error")) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(verbatim: error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            if !viewModel.domainInput.isEmpty {
                await viewModel.inspectCert()
            }
        }
        .navigationTitle("SSL Certificate Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performInspect() {
        isFieldFocused = false
        HIGFeedback.impact(.light)
        Task { await viewModel.inspectCert() }
    }
    
    // MARK: - 2. Validity Rows
    @ViewBuilder
    private func validityRows(details: SSLCertDetails) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Validity Status")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                let days = details.validityDaysRemaining ?? 0
                Text("\(days) Days Remaining")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(days > 30 ? .green : (days > 7 ? .orange : .red))
            }
            
            Spacer()
            
            if details.isCloudflareEdge {
                HIGBadge(.active("Cloudflare Universal SSL"), isCompact: true)
            } else {
                HIGBadge(.active("Origin SSL"), isCompact: true)
            }
        }
        
        ProgressView(value: min(1.0, max(0.0, Double(details.validityDaysRemaining ?? 0) / 90.0)))
            .tint((details.validityDaysRemaining ?? 0) > 30 ? .green : .orange)
        
        HStack {
            Text("Valid From")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(details.validFrom ?? "-")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
        
        HStack {
            Text("Valid Until")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(details.validUntil ?? "-")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - 3. Chain Rows
    @ViewBuilder
    private func chainRows(details: SSLCertDetails) -> some View {
        ForEach(Array(details.chainNames.enumerated()), id: \.offset) { index, name in
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill((index == 0 ? Color.green : Color.blue).opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: index == 0 ? "leaf.fill" : (index == details.chainNames.count - 1 ? "lock.shield.fill" : "link"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(index == 0 ? .green : .blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(index == 0 ? "Leaf / Server Certificate" : (index == details.chainNames.count - 1 ? "Root Authority" : "Intermediate CA"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - 4. Crypto Rows
    @ViewBuilder
    private func cryptoRows(details: SSLCertDetails) -> some View {
        if let proto = details.protocolNegotiated {
            cryptoRow(title: "Negotiated Protocol", value: proto, isBadge: true)
        }
        if let cipher = details.cipherSuite {
            cryptoRow(title: "Cipher Suite", value: cipher, isMono: true)
        }
        if let key = details.keyTypeAndBits {
            cryptoRow(title: "Key Algorithm", value: key)
        }
        if let sig = details.signatureAlgorithm {
            cryptoRow(title: "Signature Hash", value: sig)
        }
    }
    
    @ViewBuilder
    private func cryptoRow(title: LocalizedStringKey, value: String, isMono: Bool = false, isBadge: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if isBadge {
                HIGBadge(.active(value), isCompact: true)
            } else {
                Text(value)
                    .font(isMono ? .caption.monospaced() : .subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - 5. SANs Rows
    @ViewBuilder
    private func sansRows(details: SSLCertDetails) -> some View {
        ForEach(details.sans, id: \.self) { san in
            HStack {
                Image(systemName: "globe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(san)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = san
                    ToastManager.shared.showCopied()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .higTouchTarget()
            }
        }
    }
}
