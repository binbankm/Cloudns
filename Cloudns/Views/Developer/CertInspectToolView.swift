import SwiftUI

struct CertInspectToolView: View {
    @StateObject private var viewModel = SSLCertInspectorViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            List {
                // Section: Target Domain Input
                Section(header: Text("Target Domain")) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.green)
                        
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
                
                if let cert = viewModel.certDetails {
                    // Section: Status Overview
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
                                Text("Issuer CA")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(issuer)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        if let days = cert.validityDaysRemaining {
                            HStack {
                                Text("Validity Remaining")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(days) Days")
                                    .font(.subheadline)
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
                                    .cornerRadius(4)
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
                    }
                    
                    // Section: Subject Alternative Names
                    if !cert.sans.isEmpty {
                        Section(header: Text("Subject Alternative Names (SANs)")) {
                            ForEach(cert.sans, id: \.self) { san in
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(san)
                                        .font(.body.monospacedDigit())
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                } else if let err = viewModel.errorMessage {
                    Section {
                        Text(err)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("SSL Certificate Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.certDetails == nil {
                await viewModel.inspectCert()
            }
        }
    }
}
