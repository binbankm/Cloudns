import SwiftUI

// MARK: - CertInspectToolView
// Apple HIG Compliant SSL/TLS Handshake & Chain Inspector

struct CertInspectToolView: View {
    @StateObject private var viewModel = SSLCertInspectorViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // 1. Search / Input Section
            Section(header: Text("Host / Domain"), footer: Text("Inspects remote SSL/TLS certificate validity, expiration, intermediate trust chain & cryptographic cipher suites.")) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(HIGTypography.body)
                        .foregroundStyle(HIGColors.success)
                        .accessibilityHidden(true)
                    
                    TextField("example.com or hostname", text: $viewModel.domainInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(HIGTypography.body.monospacedDigit())
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
                        .higTouchTarget(44)
                        .accessibilityLabel("Clear Domain Input")
                    }
                }
                
                Button {
                    performInspect()
                } label: {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                        }
                        Text(viewModel.isLoading ? "Inspecting Handshake…" : "Inspect SSL/TLS Certificate")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading ? Color(.tertiaryLabel) : Color.higAccent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.higPressable)
                .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.certDetails == nil {
                Section {
                    HIGContentState(.loading(message: "Inspecting SSL Certificate…"))
                        .padding(.vertical, HIGTokens.Spacing.sm)
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
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HIGColors.error)
                        Text(verbatim: error)
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(HIGColors.error)
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
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text("Validity Status")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                
                let days = details.validityDaysRemaining ?? 0
                Text("\(days) Days Remaining")
                    .font(HIGTypography.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(days > 30 ? HIGColors.success : (days > 7 ? HIGColors.warning : HIGColors.error))
            }
            
            Spacer()
            
            if details.isCloudflareEdge {
                HIGBadge(.active("Cloudflare Universal SSL"), isCompact: true)
            } else {
                HIGBadge(.active("Origin SSL"), isCompact: true)
            }
        }
        
        ProgressView(value: min(1.0, max(0.0, Double(details.validityDaysRemaining ?? 0) / 90.0)))
            .tint((details.validityDaysRemaining ?? 0) > 30 ? HIGColors.success : HIGColors.warning)
        
        HStack {
            Text("Valid From")
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(details.validFrom ?? "-")
                .font(HIGTypography.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
        
        HStack {
            Text("Valid Until")
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(details.validUntil ?? "-")
                .font(HIGTypography.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - 3. Chain Rows
    @ViewBuilder
    private func chainRows(details: SSLCertDetails) -> some View {
        ForEach(Array(details.chainNames.enumerated()), id: \.offset) { index, name in
            HStack(spacing: HIGTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill((index == 0 ? HIGColors.success : Color.higAccent).opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: index == 0 ? "leaf.fill" : (index == details.chainNames.count - 1 ? "lock.shield.fill" : "link"))
                        .font(HIGTypography.caption.weight(.semibold))
                        .foregroundStyle(index == 0 ? HIGColors.success : Color.higAccent)
                }
                
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                    Text(name)
                        .font(HIGTypography.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(index == 0 ? "Leaf / Server Certificate" : (index == details.chainNames.count - 1 ? "Root Authority" : "Intermediate CA"))
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = name
                    ToastManager.shared.showCopied("CA Name Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy Certificate Name", systemImage: "doc.on.doc")
                }
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
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if isBadge {
                HIGBadge(.active(value), isCompact: true)
            } else {
                Text(value)
                    .font(isMono ? HIGTypography.caption.monospaced() : HIGTypography.subheadline)
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
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
                
                Text(san)
                    .font(HIGTypography.subheadline.monospaced())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = san
                    ToastManager.shared.showCopied("SAN Copied")
                    HIGFeedback.copied()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(HIGTypography.caption)
                        .foregroundStyle(Color.higAccent)
                }
                .buttonStyle(.higPressable)
                .higTouchTarget(44)
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = san
                    ToastManager.shared.showCopied("SAN Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy Domain", systemImage: "doc.on.doc")
                }
            }
        }
    }
}
