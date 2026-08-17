import SwiftUI

struct CertInspectToolView: View {
    @StateObject private var viewModel = SSLCertInspectorViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Section: Target Domain Input
            Section(header: Text("Target Domain")) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    
                    TextField("cloudflare.com", text: $viewModel.domainInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.inspectCert() }
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
                        Text("Inspect SSL / TLS Certificate")
                            .font(.body)
                            .foregroundStyle(.green)
                        Spacer()
                    }
                }
                .disabled(viewModel.domainInput.isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading {
                certDetailsSections(SSLCertDetails.placeholder)
                    .skeletonLoading(true)
            } else if let cert = viewModel.certDetails {
                certDetailsSections(cert)
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.25), value: viewModel.certDetails == nil)
        .navigationTitle("SSL Certificate Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.certDetails == nil {
                await viewModel.inspectCert()
            }
        }
    }
    
    @ViewBuilder
    private func certDetailsSections(_ cert: SSLCertDetails) -> some View {
        Section(header: Text("Certificate Status")) {
            HStack {
                Text("Common Name (CN)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(cert.commonName)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            
            if let issuer = cert.issuer {
                HStack {
                    Text("Issuer Organization")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(issuer)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            
            if let days = cert.validityDaysRemaining {
                HStack {
                    Text("Validity Remaining")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(days) Days")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(days > 30 ? .green : .orange)
                }
            }
            
            if let proto = cert.protocolNegotiated {
                HStack {
                    Text("Negotiated Protocol")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(proto)
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            HStack {
                Text("Edge Provider")
                    .foregroundStyle(.secondary)
                Spacer()
                if cert.isCloudflareEdge {
                    Text("Cloudflare Edge Network")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("External TLS Server")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let until = cert.validUntil {
                HStack {
                    Text("Valid Until")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(until)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        // Section: SANs
        if !cert.sans.isEmpty {
            Section(header: Text("Subject Alternative Names (\(cert.sans.count) SANs)")) {
                ForEach(cert.sans, id: \.self) { san in
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text(san)
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
