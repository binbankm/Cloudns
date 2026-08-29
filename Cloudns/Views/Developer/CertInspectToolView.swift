import SwiftUI

struct CertInspectToolView: View {
    @StateObject private var viewModel = SSLCertInspectorViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Search / Input Card
                    inputCard
                    
                    if viewModel.isLoading && viewModel.certDetails == nil {
                        VStack(spacing: 16) {
                            validityCard(details: SSLCertDetails.placeholder)
                            chainCard(details: SSLCertDetails.placeholder)
                        }
                        .redacted(reason: .placeholder)
                    } else if let details = viewModel.certDetails {
                        // 2. Validity Hero Card
                        validityCard(details: details)
                        
                        // 3. Chain Hierarchy Card
                        chainCard(details: details)
                        
                        // 4. Crypto Parameters Card
                        cryptoCard(details: details)
                        
                        // 5. SANs Domains Card
                        sansCard(details: details)
                    } else if let error = viewModel.errorMessage {
                        errorCard(message: error)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.domainInput.isEmpty {
                    await viewModel.inspectCert()
                }
            }
        }
        .navigationTitle("SSL Certificate Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
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
                    .accessibilityLabel("Clear domain input")
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Button {
                performInspect()
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    Text(viewModel.isLoading ? "Inspecting Handshake..." : "Inspect SSL/TLS Certificate")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.regular)
            .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func performInspect() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.inspectCert() }
    }
    
    // MARK: - 2. Validity Hero Card
    @ViewBuilder
    private func validityCard(details: SSLCertDetails) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Certificate Validity")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    let days = details.validityDaysRemaining ?? 0
                    Text("\(days) Days Remaining")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(days > 30 ? .green : (days > 7 ? .orange : .red))
                }
                
                Spacer()
                
                if details.isCloudflareEdge {
                    CloudnsBadge(.active("Cloudflare Universal SSL"), isCompact: false)
                } else {
                    CloudnsBadge(.active("Origin SSL"), isCompact: false)
                }
            }
            
            ProgressView(value: min(1.0, max(0.0, Double(details.validityDaysRemaining ?? 0) / 90.0)))
                .tint((details.validityDaysRemaining ?? 0) > 30 ? .green : .orange)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Valid From")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(details.validFrom ?? "-")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Valid Until")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(details.validUntil ?? "-")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - 3. Chain Card
    @ViewBuilder
    private func chainCard(details: SSLCertDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Certificate Chain Hierarchy (\(details.chainNames.count))")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 10) {
                ForEach(Array(details.chainNames.enumerated()), id: \.offset) { index, name in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill((index == 0 ? Color.green : Color.blue).opacity(0.12))
                                .frame(width: 32, height: 32)
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
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - 4. Crypto Parameters Card
    @ViewBuilder
    private func cryptoCard(details: SSLCertDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cryptographic Parameters")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 10) {
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
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    @ViewBuilder
    private func cryptoRow(title: LocalizedStringKey, value: String, isMono: Bool = false, isBadge: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if isBadge {
                CloudnsBadge(.active(value), isCompact: true)
            } else {
                Text(value)
                    .font(isMono ? .caption.monospaced() : .subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - 5. SANs Card
    @ViewBuilder
    private func sansCard(details: SSLCertDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subject Alternative Names (\(details.sans.count))")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 8) {
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
                            HapticManager.notification(.success)
                            ToastManager.shared.showCopied("SAN copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Inspection Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
