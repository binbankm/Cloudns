import SwiftUI

struct CertInspectToolView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SSLCertInspectorViewModel()
    @FocusState private var isFieldFocused: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack {
            CloudnsColor.groupedBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: CloudnsSpacing.md) {
                    // 1. Search / Input Card
                    inputCard
                    
                    if viewModel.isLoading && viewModel.certDetails == nil {
                        loadingSkeletonView
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
                .padding(.horizontal, CloudnsSpacing.md)
                .padding(.vertical, CloudnsSpacing.mdSmall)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.domainInput.isEmpty {
                    HapticManager.impact(.light)
                    await viewModel.inspectCert()
                }
            }
        }
        .navigationTitle("SSL Certificate Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(spacing: CloudnsSpacing.mdMedium) {
            HStack(spacing: CloudnsSpacing.smMd) {
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
            .padding(CloudnsSpacing.mdSmall)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            
            CloudnsButton(
                viewModel.isLoading ? "Inspecting Handshake..." : "Inspect SSL/TLS Certificate",
                icon: "checkmark.seal.fill",
                style: .primary(color: .green),
                size: .regular,
                isFullWidth: true,
                isLoading: viewModel.isLoading,
                disabled: viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                performInspect()
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Actions
    private func performInspect() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.inspectCert() }
    }
    
    // MARK: - 2. Validity Hero Card
    @ViewBuilder
    private func validityCard(details: SSLCertDetails) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdMedium) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
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
                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    Text("Valid From")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(details.validFrom ?? "-")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: CloudnsSpacing.xxs) {
                    Text("Valid Until")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(details.validUntil ?? "-")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 3. Chain Card
    @ViewBuilder
    private func chainCard(details: SSLCertDetails) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Certificate Chain Hierarchy (\(details.chainNames.count))")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.smMd) {
                ForEach(Array(details.chainNames.enumerated()), id: \.offset) { index, name in
                    HStack(spacing: CloudnsSpacing.mdSmall) {
                        ZStack {
                            Circle()
                                .fill((index == 0 ? Color.green : Color.blue).opacity(0.12))
                                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                            Image(systemName: index == 0 ? "leaf.fill" : (index == details.chainNames.count - 1 ? "lock.shield.fill" : "link"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(index == 0 ? .green : .blue)
                        }
                        
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
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
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 4. Crypto Parameters Card
    @ViewBuilder
    private func cryptoCard(details: SSLCertDetails) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Cryptographic Parameters")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.smMd) {
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
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
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
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            HStack {
                Text("Subject Alternative Names (\(details.sans.count))")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.sm) {
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
                            CloudnsToastManager.shared.showCopied("SAN copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, CloudnsSpacing.xxs)
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Inspection Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Skeleton View
    private var loadingSkeletonView: some View {
        VStack(spacing: CloudnsSpacing.md) {
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
                Text("Certificate Validity")
                    .font(.caption)
                Text("90 Days Remaining")
                    .font(.title2.weight(.bold))
                ProgressView(value: 0.8)
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
            .skeletonLoading(true)
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
                Text("Certificate Chain Hierarchy")
                    .font(.headline)
                Divider()
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        Circle().frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                        Text("Cloudflare Inc ECC CA-3")
                    }
                }
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
            .skeletonLoading(true)
        }
    }
}
