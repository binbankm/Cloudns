import SwiftUI

// MARK: - CFTraceToolView
// Apple HIG Compliant Cloudflare Global Anycast Edge PoP & Trace Inspector

struct CFTraceToolView: View {
    @StateObject private var viewModel = CFTraceViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            inputSection
            resultsSection
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            if !viewModel.host.isEmpty {
                await viewModel.queryTrace()
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
                    .higTouchTarget(44)
                }
            }
        }
        .task {
            if viewModel.traceFields.isEmpty {
                await viewModel.queryTrace()
            }
        }
    }
    
    // MARK: - 1. Input Section
    @ViewBuilder
    private var inputSection: some View {
        Section(header: Text("Target Domain / Host"), footer: Text("Traces Cloudflare's Anycast edge server, data center PoP airport code, IP & security capabilities via /cdn-cgi/trace.")) {
            HStack(spacing: HIGTokens.Spacing.sm) {
                Image(systemName: "network")
                    .font(HIGTypography.body)
                    .foregroundStyle(Color.higAccent)
                    .accessibilityHidden(true)
                
                TextField("www.cloudflare.com or domain", text: $viewModel.host)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)
                    .font(HIGTypography.body.monospacedDigit())
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
                    .buttonStyle(.plain)
                    .higTouchTarget(44)
                    .accessibilityLabel("Clear Host")
                }
            }
            
            Button {
                performTrace()
            } label: {
                HStack(spacing: HIGTokens.Spacing.xs) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    Text(viewModel.isLoading ? "Tracing Edge PoP…" : "Trace Edge PoP")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.higPressable)
            .disabled(viewModel.host.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
    }
    
    // MARK: - Results Section
    @ViewBuilder
    private var resultsSection: some View {
        if viewModel.isLoading && viewModel.traceFields.isEmpty {
            Section(header: Text("Resolved Edge PoP")) {
                popCard(colo: "SJC", loc: "San Jose, United States")
            }
        } else if !viewModel.traceFields.isEmpty {
            Section(header: Text("Resolved Edge PoP")) {
                popCard(colo: viewModel.coloCode, loc: viewModel.locCountry)
            }
            
            Section(header: Text("Network & Security Context")) {
                contextRows(fields: viewModel.traceFields, ip: viewModel.clientIp, warp: viewModel.warpStatus)
            }
            
            Section(header: Text("Raw Trace Breakdown (\(viewModel.traceFields.count) Keys)")) {
                rawTraceRows(fields: viewModel.traceFields)
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
    
    private func performTrace() {
        isFieldFocused = false
        HIGFeedback.impact(.light)
        Task { await viewModel.queryTrace() }
    }
    
    // MARK: - 2. PoP Hero Section View
    @ViewBuilder
    private func popCard(colo: String?, loc: String?) -> some View {
        let popInfo = CloudflarePoPDatabase.shared.getPoP(code: colo)
        HStack(spacing: HIGTokens.Spacing.md) {
            Text(popInfo?.flag ?? "🌐")
                .font(HIGTypography.largeTitle)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                HStack(spacing: HIGTokens.Spacing.xs) {
                    Text(popInfo?.city ?? (colo ?? "Edge PoP"))
                        .font(HIGTypography.headline)
                        .foregroundStyle(.primary)
                    
                    if let c = colo {
                        HIGBadge(.proxied(c), isCompact: true)
                    }
                }
                
                Text(popInfo?.country ?? (loc ?? "Cloudflare Global Anycast"))
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                
                if let airport = popInfo?.airport {
                    Text(airport)
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    // MARK: - 3. Context Rows
    @ViewBuilder
    private func contextRows(fields: [HTTPHeaderItem], ip: String?, warp: String?) -> some View {
        if let ip = ip {
            HStack {
                Text("Client Public IP")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(ip)
                    .font(HIGTypography.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
                
                Button {
                    UIPasteboard.general.string = ip
                    ToastManager.shared.showCopied("IP Copied")
                    HIGFeedback.copied()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(HIGTypography.caption)
                        .foregroundStyle(Color.higAccent)
                }
                .buttonStyle(.higPressable)
                .higTouchTarget(44)
            }
        }
        
        if let warp = warp {
            HStack {
                Text("WARP Status")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if warp == "on" || warp == "plus" {
                    HIGBadge(.active(warp == "plus" ? "WARP+ Active" : "WARP On"), isCompact: true)
                } else {
                    HIGBadge(.dnsOnly("WARP Off"), isCompact: true)
                }
            }
        }
        
        if let gateway = fields.first(where: { $0.key.lowercased() == "gateway" })?.value {
            HStack {
                Text("Zero Trust Gateway")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                HIGBadge(gateway == "on" ? .active("Protected") : .warning("Bypassed"), isCompact: true)
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
    
    @ViewBuilder
    private func contextRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(HIGTypography.subheadline.monospaced())
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - 4. Raw Trace Rows
    @ViewBuilder
    private func rawTraceRows(fields: [HTTPHeaderItem]) -> some View {
        ForEach(fields) { field in
            HStack {
                Text(field.key)
                    .font(HIGTypography.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(field.value)
                    .font(HIGTypography.caption.monospaced())
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                
                Button {
                    UIPasteboard.general.string = "\(field.key)=\(field.value)"
                    ToastManager.shared.showCopied("\(field.key) Copied")
                    HIGFeedback.copied()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.higPressable)
                .higTouchTarget(44)
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = "\(field.key)=\(field.value)"
                    ToastManager.shared.showCopied("Key-Value Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy Line", systemImage: "doc.on.doc")
                }
                Button {
                    UIPasteboard.general.string = field.value
                    ToastManager.shared.showCopied("Value Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy Value", systemImage: "text.alignleft")
                }
            }
        }
    }
    
    private func copyRawTrace() {
        let text = viewModel.traceFields.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        ToastManager.shared.showCopied("Raw Trace Copied")
        HIGFeedback.copied()
    }
    
    private func copyCurlCommand() {
        let cmd = "curl -sL https://\(viewModel.host)/cdn-cgi/trace"
        UIPasteboard.general.string = cmd
        ToastManager.shared.showCopied("cURL Command Copied")
        HIGFeedback.copied()
    }
}
