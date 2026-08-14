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
                            .foregroundColor(.green)
                        
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
                                .font(.body.weight(.semibold))
                                .foregroundColor(.green)
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
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(cert.commonName)
                                .font(.body.monospaced())
                                .foregroundColor(.primary)
                        }
                        
                        if let issuer = cert.issuer {
                            HStack {
                                Text("Issuer CA")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(issuer)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let days = cert.validityDaysRemaining {
                            HStack {
                                Text("Validity Remaining")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(days) Days")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(days > 30 ? .green : .orange)
                            }
                        }
                        
                        if let proto = cert.protocolNegotiated {
                            HStack {
                                Text("Negotiated Protocol")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(proto)
                                    .font(.caption.monospaced())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.12))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                        }
                        
                        HStack {
                            Text("Edge Provider")
                                .foregroundColor(.secondary)
                            Spacer()
                            if cert.isCloudflareEdge {
                                Text("Cloudflare Edge Network")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.orange)
                            } else {
                                Text("External TLS Server")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                                        .foregroundColor(.secondary)
                                    Text(san)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                } else if let err = viewModel.errorMessage {
                    Section {
                        Text(err)
                            .font(.subheadline)
                            .foregroundColor(.red)
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
