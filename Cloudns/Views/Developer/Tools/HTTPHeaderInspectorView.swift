import SwiftUI

struct HTTPHeaderInspectorView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    @State private var headerSearchText = ""
    
    var filteredHeaders: [HTTPHeaderItem] {
        guard let res = viewModel.httpResult else { return [] }
        if headerSearchText.isEmpty { return res.headers }
        let query = headerSearchText.lowercased()
        return res.headers.filter { $0.key.lowercased().contains(query) || $0.value.lowercased().contains(query) }
    }
    
    var body: some View {
        List {
            // 1. Target URL & Method Section
            Section(header: Text("Request Configuration"), footer: Text("Inspects live Cloudflare Edge HTTP response status, CF-Ray, caching status & custom headers.")) {
                HStack(spacing: 10) {
                    Image(systemName: "link")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("https://example.com", text: $viewModel.httpUrlInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(.body.monospacedDigit())
                        .submitLabel(.go)
                        .onSubmit {
                            performInspect()
                        }
                    
                    if !viewModel.httpUrlInput.isEmpty {
                        Button {
                            viewModel.httpUrlInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear URL")
                    }
                }
                
                Picker("HTTP Method", selection: $viewModel.httpMethod) {
                    ForEach(viewModel.httpMethods, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                
                Button {
                    performInspect()
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isHttpLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.up.right.circle.fill")
                        }
                        Text(viewModel.isHttpLoading ? "Connecting Edge..." : "Inspect Edge Response")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.httpUrlInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isHttpLoading)
            }
            
            if viewModel.isHttpLoading {
                Section(header: Text("Edge Response Summary")) {
                    edgeSummaryRows(result: HTTPInspectionResult.placeholder)
                }
                .redacted(reason: .placeholder)
            } else if let result = viewModel.httpResult {
                // 2. Edge & Performance Hero Section
                Section(header: Text("Edge Response Summary")) {
                    edgeSummaryRows(result: result)
                }
                
                // 3. Response Headers Section
                Section(header: Text("Response Headers (\(result.headers.count))")) {
                    headersRows(result: result)
                }
            } else if let error = viewModel.httpError {
                Section(header: Text("Error")) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            if !viewModel.httpUrlInput.isEmpty {
                await viewModel.inspectHTTP()
            }
        }
        .navigationTitle("HTTP & Cache Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let result = viewModel.httpResult {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        copyAllHeaders(result)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .accessibilityLabel("Copy all headers")
                }
            }
        }
    }
    
    private func performInspect() {
        isFieldFocused = false
        HIGFeedback.impact(.light)
        Task { await viewModel.inspectHTTP() }
    }
    
    // MARK: - 2. Edge Summary Rows
    @ViewBuilder
    private func edgeSummaryRows(result: HTTPInspectionResult) -> some View {
        HStack {
            Text("Status Code")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 6) {
                Text("\(result.statusCode)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(result.statusCode < 400 ? .green : .red)
                Text(result.statusText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        
        if let cache = result.cfCacheStatus {
            HStack {
                Text("CF-Cache-Status")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                cacheStatusBadge(cache)
            }
        }
        
        if let ray = result.cfRay {
            let coloCode = ray.split(separator: "-").last.map(String.init) ?? ""
            let popInfo = CloudflarePoPDatabase.shared.getPoP(code: coloCode)
            
            HStack {
                Text("CF-Ray Trace")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let info = popInfo {
                    Text("\(info.flag) \(info.city)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                HIGBadge(.proxied(coloCode.isEmpty ? ray : coloCode), isCompact: true)
            }
        }
        
        HStack {
            Text("Protocol")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if result.isHTTP3Supported {
                HIGBadge(.active("HTTP/3 (QUIC)"), isCompact: true)
            } else {
                Text(result.httpVersion)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        
        if let enc = result.contentEncoding {
            HStack {
                Text("Compression")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(enc.uppercased())
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.primary)
            }
        }
        
        HStack {
            Text("Edge TTFB")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.1f ms", result.ttfbMs))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.green)
        }
        
        HStack {
            Text("Total Duration")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.1f ms", result.durationMs))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - 3. Headers Rows
    @ViewBuilder
    private func headersRows(result: HTTPInspectionResult) -> some View {
        ForEach(filteredHeaders) { header in
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(header.key)
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundStyle(.blue)
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = "\(header.key): \(header.value)"
                        ToastManager.shared.showCopied()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .higTouchTarget()
                }
                
                Text(header.value)
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 2)
        }
    }
    
    @ViewBuilder
    private func cacheStatusBadge(_ status: String) -> some View {
        let upper = status.uppercased()
        switch upper {
        case "HIT":
            HIGBadge(.active("HIT (Edge Cached)"), isCompact: true)
        case "MISS":
            HIGBadge(.warning("MISS (Fetched Origin)"), isCompact: true)
        case "DYNAMIC":
            HIGBadge(.dnsOnly("DYNAMIC (No Cache)"), isCompact: true)
        case "BYPASS":
            HIGBadge(.warning("BYPASS (Rule Bypassed)"), isCompact: true)
        case "EXPIRED":
            HIGBadge(.error("EXPIRED (Stale Cache)"), isCompact: true)
        case "REVALIDATED":
            HIGBadge(.active("REVALIDATED"), isCompact: true)
        default:
            HIGBadge(.proxied(upper), isCompact: true)
        }
    }
    
    private func copyAllHeaders(_ result: HTTPInspectionResult) {
        let text = result.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        ToastManager.shared.showCopied()
    }
}
