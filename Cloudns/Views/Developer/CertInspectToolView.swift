import SwiftUI

struct CertInspectToolView: View {
    @StateObject private var viewModel = SSLCertInspectorViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Target Domain Input
            Section(header: Text("Target Domain")) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    
                    TextField("example.com", text: $viewModel.domainInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.inspectCert() }
                        }
                    
                    if !viewModel.domainInput.isEmpty {
                        Button {
                            viewModel.domainInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Button {
                    isFieldFocused = false
                    HapticManager.impact(.light)
                    Task { await viewModel.inspectCert() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                        }
                        Text("Inspect SSL/TLS Certificate")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.green)
                        Spacer()
                    }
                }
                .disabled(viewModel.domainInput.isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.certDetails == nil {
                certDetailsSection(details: SSLCertDetails.placeholder)
                    .skeletonLoading(true)
            } else if let details = viewModel.certDetails {
                certDetailsSection(details: details)
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("SSL Certificate Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func certDetailsSection(details: SSLCertDetails) -> some View {
        certValiditySection(details: details)
        certChainSection(details: details)
        certCryptoSection(details: details)
        certSansSection(details: details)
    }
    
    @ViewBuilder
    private func certValiditySection(details: SSLCertDetails) -> some View {
        Section(header: Text("Certificate Validity & Expiration")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Days Remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        let days = details.validityDaysRemaining ?? 0
                        Text("\(days) Days")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(days > 30 ? .green : (days > 7 ? .orange : .red))
                    }
                    
                    Spacer()
                    
                    if details.isCloudflareEdge {
                        CloudnsBadge(.active("Cloudflare Universal SSL"), isCompact: false)
                    } else {
                        CloudnsBadge(.active("Origin SSL"), isCompact: false)
                    }
                }
                
                // Progress Bar
                ProgressView(value: min(1.0, max(0.0, Double(details.validityDaysRemaining ?? 0) / 90.0)))
                    .tint((details.validityDaysRemaining ?? 0) > 30 ? .green : .orange)
                
                HStack {
                    Text("Valid From: \(details.validFrom ?? "-")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Valid Until: \(details.validUntil ?? "-")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private func certChainSection(details: SSLCertDetails) -> some View {
        Section(header: Text("Certificate Chain Hierarchy (\(details.chainNames.count) Certificates)")) {
            ForEach(Array(details.chainNames.enumerated()), id: \.offset) { index, name in
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: index == 0 ? "leaf.fill" : (index == details.chainNames.count - 1 ? "lock.shield.fill" : "link"))
                        .foregroundStyle(index == 0 ? .green : .blue)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            if index == 0 {
                                CloudnsBadge(.proxied("Leaf / Server"), isCompact: true)
                            } else if index == details.chainNames.count - 1 {
                                CloudnsBadge(.active("Root CA"), isCompact: true)
                            } else {
                                CloudnsBadge(.dnsOnly("Intermediate CA"), isCompact: true)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 3)
            }
        }
    }
    
    @ViewBuilder
    private func certCryptoSection(details: SSLCertDetails) -> some View {
        Section(header: Text("Cryptographic Parameters")) {
            if let proto = details.protocolNegotiated {
                HStack {
                    Text("Negotiated Protocol")
                        .foregroundStyle(.secondary)
                    Spacer()
                    CloudnsBadge(.active(proto), isCompact: true)
                }
            }
            
            if let cipher = details.cipherSuite {
                HStack {
                    Text("Cipher Suite")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(cipher)
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            
            if let key = details.keyTypeAndBits {
                HStack {
                    Text("Public Key Algorithm")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(key)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            
            if let sig = details.signatureAlgorithm {
                HStack {
                    Text("Signature Hash")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(sig)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func certSansSection(details: SSLCertDetails) -> some View {
        Section(header: Text("Subject Alternative Names (SANs) (\(details.sans.count))")) {
            ForEach(details.sans, id: \.self) { san in
                HStack {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(san)
                        .font(.subheadline.monospaced())
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = san
                        HapticManager.notification(.success)
                        ToastManager.shared.showCopied("SAN copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
