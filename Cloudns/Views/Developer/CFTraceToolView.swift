import SwiftUI

struct CFTraceToolView: View {
    @StateObject private var viewModel = CFTraceViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            List {
                // Section: Host Input
                Section(header: Text("Trace Host")) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.orange)
                        
                        TextField("www.cloudflare.com", text: $viewModel.host)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isFieldFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                Task { await viewModel.queryTrace() }
                            }
                    }
                    
                    Button {
                        isFieldFocused = false
                        Task { await viewModel.queryTrace() }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.trailing, 4)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text("Trace PoP & Network")
                                .font(.body)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.host.isEmpty || viewModel.isLoading)
                }
                
                // Section: PoP & Summary
                if let colo = viewModel.coloCode {
                    Section(header: Text("Connection Summary")) {
                        HStack {
                            Text("Edge PoP Data Center")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(colo)
                                .font(.body.monospacedDigit())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                        }
                        
                        if let ip = viewModel.clientIp {
                            HStack {
                                Text("Client IP")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(ip)
                                    .font(.body.monospacedDigit())
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let loc = viewModel.locCountry {
                            HStack {
                                Text("Country / Region")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(loc)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let warp = viewModel.warpStatus {
                            HStack {
                                Text("Cloudflare WARP")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(warp.uppercased())
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(warp == "on" || warp == "plus" ? .green : .secondary)
                            }
                        }
                    }
                }
                
                // Section: All Trace Fields
                if !viewModel.traceFields.isEmpty {
                    Section(header: HStack {
                        Text("All Trace Fields (\(viewModel.traceFields.count))")
                        Spacer()
                        Button {
                            let text = viewModel.traceFields.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
                            UIPasteboard.general.string = text
                            ToastManager.shared.showCopied("Trace copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                    }) {
                        ForEach(viewModel.traceFields) { item in
                            HStack {
                                Text(item.key)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(item.value)
                                    .font(.body.monospacedDigit())
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 2)
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
        .navigationTitle("Cloudflare Trace")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.traceFields.isEmpty {
                await viewModel.queryTrace()
            }
        }
    }
}
