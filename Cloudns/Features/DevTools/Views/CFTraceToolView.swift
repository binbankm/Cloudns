import SwiftUI

struct CFTraceToolView: View {
    // MARK: - Properties
    @StateObject private var viewModel = CFTraceViewModel()
    @FocusState private var isFieldFocused: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Input Card
                    inputCard
                    
                    if viewModel.isLoading && viewModel.traceFields.isEmpty {
                        loadingSkeletonView
                    } else if !viewModel.traceFields.isEmpty {
                        // 2. PoP Hero Card
                        popCard(colo: viewModel.coloCode, loc: viewModel.locCountry)
                        
                        // 3. Security & Context Card
                        contextCard(fields: viewModel.traceFields, ip: viewModel.clientIp, warp: viewModel.warpStatus)
                        
                        // 4. Raw Trace Properties Card
                        rawTraceCard(fields: viewModel.traceFields)
                    } else if let error = viewModel.errorMessage {
                        errorCard(message: error)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.host.isEmpty {
                    HapticManager.impact(.light)
                    await viewModel.queryTrace()
                }
            }
        }
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
                    .accessibilityLabel("Export Trace")
                }
            }
        }
        .task {
            if viewModel.traceFields.isEmpty {
                await viewModel.queryTrace()
            }
        }
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "network")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                
                TextField("www.cloudflare.com or custom domain", text: $viewModel.host)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)
                    .font(.body.monospacedDigit())
                    .submitLabel(.search)
                    .onSubmit {
                        performTrace()
                    }
                
                if !viewModel.host.isEmpty {
                    Button {
                        viewModel.host = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear host")
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Button {
                performTrace()
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    Text(viewModel.isLoading ? "Tracing Edge PoP..." : "Trace Edge PoP & Network")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.regular)
            .disabled(viewModel.host.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - Actions
    private func performTrace() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.queryTrace() }
    }
    
    // MARK: - 2. PoP Hero Card
    @ViewBuilder
    private func popCard(colo: String?, loc: String?) -> some View {
        let popInfo = CloudflarePoPDatabase.shared.getPoP(code: colo)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(popInfo?.flag ?? "🌐")
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 3) {
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
                Divider()
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
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 3. Context Card
    @ViewBuilder
    private func contextCard(fields: [HTTPHeaderItem], ip: String?, warp: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client & Security Context")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 10) {
                if let ip = ip {
                    HStack {
                        Text("Client Public IP")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ip)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.primary)
                        
                        Button {
                            UIPasteboard.general.string = ip
                            HapticManager.notification(.success)
                            CloudnsToastManager.shared.showCopied("IP copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                if let warp = warp {
                    HStack {
                        Text("WARP Status")
                            .font(.subheadline)
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
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        CloudnsBadge(gateway == "on" ? .active("Protected") : .warning("Bypassed"), isCompact: true)
                    }
                }
                
                if let kex = fields.first(where: { $0.key.lowercased() == "kex" })?.value {
                    contextRow(title: "Key Exchange (KEX)", value: kex)
                }
                if let tls = fields.first(where: { $0.key.lowercased() == "tls" })?.value {
                    contextRow(title: "TLS Version", value: tls)
                }
                if let http = fields.first(where: { $0.key.lowercased() == "http" })?.value {
                    contextRow(title: "HTTP Protocol", value: http.uppercased())
                }
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    @ViewBuilder
    private func contextRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - 4. Raw Trace Card
    @ViewBuilder
    private func rawTraceCard(fields: [HTTPHeaderItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Raw Trace Properties (\(fields.count))")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    copyRawTrace()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            Divider()
            
            VStack(spacing: 8) {
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
                    .padding(.vertical, 1)
                }
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Trace Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - Skeleton View
    private var loadingSkeletonView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle().frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text("San Francisco (SFO)").font(.title3.weight(.bold))
                        Text("United States")
                    }
                }
            }
            .padding(16)
            .cloudnsCard(style: .frosted, cornerRadius: 16)
            .skeletonLoading(true)
        }
    }
    
    private func copyRawTrace() {
        let text = viewModel.traceFields.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        CloudnsToastManager.shared.showCopied("Raw trace copied")
    }
    
    private func copyCurlCommand() {
        let cmd = "curl -sL https://\(viewModel.host)/cdn-cgi/trace"
        UIPasteboard.general.string = cmd
        HapticManager.notification(.success)
        CloudnsToastManager.shared.showCopied("cURL command copied")
    }
}
