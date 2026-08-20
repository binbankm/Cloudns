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
            // Target URL & Method
            Section(header: Text("Inspect URL & Method")) {
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("https://example.com", text: $viewModel.httpUrlInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.go)
                        .onSubmit {
                            Task { await viewModel.inspectHTTP() }
                        }
                    
                    if !viewModel.httpUrlInput.isEmpty {
                        Button {
                            viewModel.httpUrlInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Picker("HTTP Method", selection: $viewModel.httpMethod) {
                    ForEach(viewModel.httpMethods, id: \.self) { method in
                        Text(method).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                
                Button {
                    isFieldFocused = false
                    HapticManager.impact(.light)
                    Task { await viewModel.inspectHTTP() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isHttpLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "arrow.up.right.circle.fill")
                        }
                        Text("Inspect Edge Response")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
                .disabled(viewModel.httpUrlInput.isEmpty || viewModel.isHttpLoading)
            }
            
            if viewModel.isHttpLoading {
                Section(header: Text("Requesting Edge Headers...")) {
                    HStack {
                        Text("HTTP/2 200 OK")
                        Spacer()
                        Text("42.5 ms")
                    }
                    .skeletonLoading(true)
                }
            } else if let result = viewModel.httpResult {
                // 1. Edge & Cache Performance Dashboard
                Section(header: Text("Cloudflare Edge Summary")) {
                    HStack {
                        Text("HTTP Status")
                            .foregroundStyle(.secondary)
                        Spacer()
                        CloudnsBadge(result.statusCode < 400 ? .active("\(result.statusCode) \(result.statusText)") : .error("\(result.statusCode) \(result.statusText)"), isCompact: false)
                    }
                    
                    if let cache = result.cfCacheStatus {
                        HStack {
                            Text("CF-Cache-Status")
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
                        Text("Transport Protocol")
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
                            Text("Compression (Encoding)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(enc.uppercased())
                                .font(.subheadline.monospaced())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    HStack {
                        Text("Edge TTFB (First Byte)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f ms", result.ttfbMs))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Text("Total Duration")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f ms", result.durationMs))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
                
                // 2. All Headers List
                Section(header: HStack {
                    Text("Response Headers (\(result.headers.count))")
                    Spacer()
                    Button {
                        copyAllHeaders(result)
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                }) {
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
                                    ToastManager.shared.showCopied("Header copied")
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
                        .padding(.vertical, 3)
                    }
                }
            } else if let error = viewModel.httpError {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("HTTP & Cache Inspector")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func copyAllHeaders(_ result: HTTPInspectionResult) {
        let text = result.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        HapticManager.notification(.success)
        ToastManager.shared.showCopied("All headers copied")
    }
}
