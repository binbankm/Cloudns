import SwiftUI

struct CFTraceToolView: View {
    @StateObject private var viewModel = CFTraceViewModel()
    @FocusState private var isFieldFocused: Bool
    @State private var showingCopyToast = false
    
    var body: some View {
        List {
            // MARK: - Host Input
            Section(header: Text("Trace Host")) {
                HStack {
                    Image(systemName: "network")
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    
                    TextField("www.cloudflare.com", text: $viewModel.host)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.queryTrace() }
                        }
                    
                    if !viewModel.host.isEmpty {
                        Button {
                            viewModel.host = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Button {
                    isFieldFocused = false
                    HapticManager.impact(.light)
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
                        Text("Trace Edge PoP & Network")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                }
                .disabled(viewModel.host.isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.traceFields.isEmpty {
                traceSections(fields: HTTPHeaderItem.tracePlaceholders, colo: "SFO", ip: "1.1.1.1", loc: "US", warp: "plus")
                    .skeletonLoading(true)
            } else if !viewModel.traceFields.isEmpty {
                traceSections(fields: viewModel.traceFields, colo: viewModel.coloCode, ip: viewModel.clientIp, loc: viewModel.locCountry, warp: viewModel.warpStatus)
            } else if let error = viewModel.errorMessage {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Cloudflare Trace")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.traceFields.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            copyRawTrace()
                        } label: {
                            Label("Copy Raw Trace", systemImage: "doc.on.doc")
                        }
                        Button {
                            copyCurlCommand()
                        } label: {
                            Label("Copy cURL Command", systemImage: "terminal")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task {
            if viewModel.traceFields.isEmpty {
                await viewModel.queryTrace()
            }
        }
    }
    
    @ViewBuilder
    private func traceSections(fields: [HTTPHeaderItem], colo: String?, ip: String?, loc: String?, warp: String?) -> some View {
        popSection(colo: colo, loc: loc)
        clientContextSection(fields: fields, ip: ip, warp: warp)
        rawTraceSection(fields: fields)
    }
    
    @ViewBuilder
    private func popSection(colo: String?, loc: String?) -> some View {
        let popInfo = CloudflarePoPDatabase.shared.getPoP(code: colo)
        Section(header: Text("Edge PoP Data Center")) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Text(popInfo?.flag ?? "🌐")
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(popInfo?.city ?? (colo ?? "Edge PoP"))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            if let c = colo {
                                CloudnsBadge(.proxied(c), isCompact: false)
                            }
                        }
                        
                        Text(popInfo?.country ?? (loc ?? "Cloudflare Global Anycast"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                if let airport = popInfo?.airport {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(airport)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private func clientContextSection(fields: [HTTPHeaderItem], ip: String?, warp: String?) -> some View {
        Section(header: Text("Client & Security Context")) {
            if let ip = ip {
                HStack {
                    Text("Client Public IP")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ip)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.primary)
                    
                    Button {
                        UIPasteboard.general.string = ip
                        HapticManager.notification(.success)
                        ToastManager.shared.showCopied("IP copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let warp = warp {
                HStack {
                    Text("WARP Client Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if warp == "on" || warp == "plus" {
                        CloudnsBadge(.active(warp == "plus" ? "WARP+ Active" : "WARP On"), isCompact: true)
                    } else {
                        CloudnsBadge(.dnsOnly("WARP Off"), isCompact: true)
                    }
                }
            }
            
            if let gateway = fields.first(where: { $0.key.lowercased() == "gateway" })?.value {
                HStack {
                    Text("Zero Trust Gateway")
                        .foregroundStyle(.secondary)
                    Spacer()
                    CloudnsBadge(gateway == "on" ? .active("Protected") : .warning("Bypassed"), isCompact: true)
                }
            }
            
            if let kex = fields.first(where: { $0.key.lowercased() == "kex" })?.value {
                HStack {
                    Text("Key Exchange (KEX)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(kex)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.primary)
                }
            }
            
            if let tls = fields.first(where: { $0.key.lowercased() == "tls" })?.value {
                HStack {
                    Text("TLS Protocol Version")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(tls)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.primary)
                }
            }
            
            if let http = fields.first(where: { $0.key.lowercased() == "http" })?.value {
                HStack {
                    Text("HTTP Transport Protocol")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(http.uppercased())
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func rawTraceSection(fields: [HTTPHeaderItem]) -> some View {
        Section(header: Text("Raw Trace Properties (\(fields.count))")) {
            ForEach(fields) { field in
                HStack {
                    Text(field.key)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(field.value)
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private func copyRawTrace() {
        let text = viewModel.traceFields.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        ToastManager.shared.showCopied("Raw trace copied")
    }
    
    private func copyCurlCommand() {
        let cmd = "curl -sL https://\(viewModel.host)/cdn-cgi/trace"
        UIPasteboard.general.string = cmd
        HapticManager.notification(.success)
        ToastManager.shared.showCopied("cURL command copied")
    }
}
