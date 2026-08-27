import SwiftUI

struct HTTPHeaderInspectorView: View {
    // MARK: - Properties
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    @State private var headerSearchText = ""
    
    var filteredHeaders: [HTTPHeaderItem] {
        guard let res = viewModel.httpResult else { return [] }
        if headerSearchText.isEmpty { return res.headers }
        let query = headerSearchText.lowercased()
        return res.headers.filter { $0.key.lowercased().contains(query) || $0.value.lowercased().contains(query) }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 1. URL & Method Config Card
                    inputCard
                    
                    if viewModel.isHttpLoading {
                        loadingSkeletonView
                    } else if let result = viewModel.httpResult {
                        // 2. Edge & Performance Hero Card
                        edgeSummaryCard(result: result)
                        
                        // 3. Response Headers Card
                        headersCard(result: result)
                    } else if let error = viewModel.httpError {
                        errorCard(message: error)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.httpUrlInput.isEmpty {
                    HapticManager.impact(.light)
                    await viewModel.inspectHTTP()
                }
            }
        }
        .navigationTitle("HTTP & Cache Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .font(.title3)
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
                    .accessibilityLabel("Clear URL")
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
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
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up.right.circle.fill")
                    }
                    Text(viewModel.isHttpLoading ? "Connecting Edge..." : "Inspect Edge Response")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.regular)
            .disabled(viewModel.httpUrlInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isHttpLoading)
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - Actions
    private func performInspect() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.inspectHTTP() }
    }
    
    // MARK: - 2. Edge Summary Card
    @ViewBuilder
    private func edgeSummaryCard(result: HTTPInspectionResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Edge Response Summary")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("\(result.statusCode)")
                            .font(.title2.weight(.bold).monospacedDigit())
                            .foregroundStyle(result.statusCode < 400 ? .green : .red)
                        Text(result.statusText)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
                
                if let cache = result.cfCacheStatus {
                    cacheStatusBadge(cache)
                }
            }
            
            Divider()
            
            VStack(spacing: 10) {
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
                        CloudnsBadge(.proxied(coloCode.isEmpty ? ray : coloCode), isCompact: true)
                    }
                }
                
                HStack {
                    Text("Protocol")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if result.isHTTP3Supported {
                        CloudnsBadge(.active("HTTP/3 (QUIC)"), isCompact: true)
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
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 3. Headers Card
    @ViewBuilder
    private func headersCard(result: HTTPInspectionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Response Headers (\(result.headers.count))")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    copyAllHeaders(result)
                } label: {
                    Label("Copy All", systemImage: "doc.on.doc")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Filter Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Filter headers...", text: $headerSearchText)
                    .font(.caption)
                if !headerSearchText.isEmpty {
                    Button {
                        headerSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            Divider()
            
            VStack(spacing: 8) {
                ForEach(filteredHeaders) { header in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(header.key)
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(.blue)
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = "\(header.key): \(header.value)"
                                HapticManager.notification(.success)
                                CloudnsToastManager.shared.showCopied("Header copied")
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text(header.value)
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    @ViewBuilder
    private func cacheStatusBadge(_ status: String) -> some View {
        let upper = status.uppercased()
        switch upper {
        case "HIT":
            CloudnsBadge(.active("HIT (Edge Cached)"), isCompact: true)
        case "MISS":
            CloudnsBadge(.warning("MISS (Fetched Origin)"), isCompact: true)
        case "DYNAMIC":
            CloudnsBadge(.dnsOnly("DYNAMIC (No Cache)"), isCompact: true)
        case "BYPASS":
            CloudnsBadge(.warning("BYPASS (Rule Bypassed)"), isCompact: true)
        case "EXPIRED":
            CloudnsBadge(.error("EXPIRED (Stale Cache)"), isCompact: true)
        case "REVALIDATED":
            CloudnsBadge(.active("REVALIDATED"), isCompact: true)
        default:
            CloudnsBadge(.proxied(upper), isCompact: true)
        }
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Inspection Failed")
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
                Text("Edge Response Summary")
                    .font(.caption)
                Text("200 OK").font(.title2.weight(.bold))
            }
            .padding(16)
            .cloudnsCard(style: .frosted, cornerRadius: 16)
            .skeletonLoading(true)
        }
    }
    
    private func copyAllHeaders(_ result: HTTPInspectionResult) {
        let text = result.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        CloudnsToastManager.shared.showCopied("All headers copied")
    }
}
