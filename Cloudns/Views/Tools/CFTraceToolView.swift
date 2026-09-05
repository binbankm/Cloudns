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
        Section {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                
                TextField("www.cloudflare.com or domain", text: $viewModel.host)
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
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear Host")
                }
            }
            
            Button {
                performTrace()
            } label: {
                HStack(spacing: 6) {
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
            .disabled(viewModel.host.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        } header: {
            Text("Target Domain / Host")
        } footer: {
            Text("Traces Cloudflare's Anycast edge server, data center PoP airport code, IP & security capabilities via /cdn-cgi/trace.")
        }
    }
    
    // MARK: - Results Section
    @ViewBuilder
    private var resultsSection: some View {
        if viewModel.isLoading && viewModel.traceFields.isEmpty {
            Section("Resolved Edge PoP") {
                popCard(colo: "SJC", loc: "San Jose, United States")
            }
        } else if !viewModel.traceFields.isEmpty {
            Section("Resolved Edge PoP") {
                popCard(colo: viewModel.coloCode, loc: viewModel.locCountry)
            }
            
            Section("Network & Security Context") {
                contextRows(fields: viewModel.traceFields, ip: viewModel.clientIp, warp: viewModel.warpStatus)
            }
            
            Section("Raw Trace Breakdown (\(viewModel.traceFields.count) Keys)") {
                rawTraceRows(fields: viewModel.traceFields)
            }
        } else if let error = viewModel.errorMessage {
            Section("Error") {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(verbatim: error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    private func performTrace() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.queryTrace() }
    }
    
    // MARK: - 2. PoP Hero Section View
    @ViewBuilder
    private func popCard(colo: String?, loc: String?) -> some View {
        let popInfo = CloudflarePoPDatabase.shared.getPoP(code: colo)
        HStack(spacing: 12) {
            Text(popInfo?.flag ?? "🌐")
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(popInfo?.city ?? (colo ?? "Edge PoP"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let c = colo {
                        Text(c)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange.opacity(0.12)))
                    }
                }
                
                Text(popInfo?.country ?? (loc ?? "Cloudflare Global Anycast"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let airport = popInfo?.airport {
                    Text(airport)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - 3. Context Rows
    @ViewBuilder
    private func contextRows(fields: [HTTPHeaderItem], ip: String?, warp: String?) -> some View {
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
                    copyToClipboard(ip, toast: "IP Copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        
        if let warp = warp {
            HStack {
                Text("WARP Status")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if warp == "on" || warp == "plus" {
                    let title = warp == "plus" ? "WARP+ Active" : "WARP On"
                    Text(title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                } else {
                    Text("WARP Off")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }
            }
        }
        
        if let gateway = fields.first(where: { $0.key.lowercased() == "gateway" })?.value {
            HStack {
                Text("Zero Trust Gateway")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                let isProtected = gateway == "on"
                Text(isProtected ? "Protected" : "Bypassed")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isProtected ? Color.green : Color.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((isProtected ? Color.green : Color.orange).opacity(0.12)))
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
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - 4. Raw Trace Rows
    @ViewBuilder
    private func rawTraceRows(fields: [HTTPHeaderItem]) -> some View {
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
                
                Button {
                    copyToClipboard("\(field.key)=\(field.value)", toast: "\(field.key) Copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .contextMenu {
                Button {
                    copyToClipboard("\(field.key)=\(field.value)", toast: "Key-Value Copied")
                } label: {
                    Label("Copy Line", systemImage: "doc.on.doc")
                }
                Button {
                    copyToClipboard(field.value, toast: "Value Copied")
                } label: {
                    Label("Copy Value", systemImage: "text.alignleft")
                }
            }
        }
    }
    
    private func copyRawTrace() {
        let text = viewModel.traceFields.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
        copyToClipboard(text, toast: "Raw Trace Copied")
    }
    
    private func copyCurlCommand() {
        let cmd = "curl -sL https://\(viewModel.host)/cdn-cgi/trace"
        copyToClipboard(cmd, toast: "cURL Command Copied")
    }
}
