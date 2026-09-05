import SwiftUI

// MARK: - HTTPHeaderInspectorView
// Apple HIG Compliant Cloudflare Edge HTTP & Cache Header Inspector

struct HTTPHeaderInspectorView: View {
    @StateObject private var viewModel = HTTPHeaderInspectorViewModel()
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
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .foregroundStyle(.tint)
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
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
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
                        Text(viewModel.isHttpLoading ? "Connecting Edge…" : "Inspect Edge Response")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.httpUrlInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isHttpLoading)
            } header: {
                Text("Request Configuration")
            } footer: {
                Text("Inspects live Cloudflare Edge HTTP response status, CF-Ray, caching status & custom headers.")
            }
            
            if viewModel.isHttpLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Inspecting Edge Response…")
                            .padding(.vertical, 8)
                        Spacer()
                    }
                }
            } else if let result = viewModel.httpResult {
                // 2. Edge & Performance Hero Section
                Section("Edge Response Summary") {
                    edgeSummaryRows(result: result)
                }
                
                // 3. Response Headers Section
                Section("Response Headers (\(result.headers.count))") {
                    headersRows(result: result)
                }
            } else if let error = viewModel.httpError {
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
                    .accessibilityLabel("Copy All Headers")
                }
            }
        }
    }
    
    private func performInspect() {
        isFieldFocused = false
        HapticManager.impact(.light)
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
                    .foregroundStyle(result.statusCode < 400 ? Color.green : Color.red)
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
            HStack {
                Text("CF-Ray ID")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(ray)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.primary)
            }
            .contextMenu {
                Button {
                    copyToClipboard(ray, toast: "CF-Ray Copied")
                } label: {
                    Label("Copy CF-Ray ID", systemImage: "doc.on.doc")
                }
            }
        }
        
        HStack {
            Text("Total TTFB Latency")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(result.durationMs.formatted(.number.precision(.fractionLength(1)))) ms")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
    
    @ViewBuilder
    private func headersRows(result: HTTPInspectionResult) -> some View {
        ForEach(filteredHeaders) { header in
            HStack(alignment: .top, spacing: 8) {
                Text(header.key)
                    .font(.caption.monospaced().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 120, alignment: .leading)
                
                Text(header.value)
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                
                Spacer()
                
                Button {
                    copyToClipboard("\(header.key): \(header.value)", toast: "Header Copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
            .contextMenu {
                Button {
                    copyToClipboard("\(header.key): \(header.value)", toast: "Header Copied")
                } label: {
                    Label("Copy Line", systemImage: "doc.on.doc")
                }
                Button {
                    copyToClipboard(header.value, toast: "Value Copied")
                } label: {
                    Label("Copy Value", systemImage: "text.alignleft")
                }
            }
        }
    }
    
    @ViewBuilder
    private func cacheStatusBadge(_ status: String) -> some View {
        let upper = status.uppercased()
        let (color, text): (Color, String) = {
            if upper.contains("HIT") {
                return (.green, "HIT")
            } else if upper.contains("MISS") {
                return (.orange, "MISS")
            } else if upper.contains("DYNAMIC") {
                return (.blue, "DYNAMIC")
            } else if upper.contains("BYPASS") {
                return (.secondary, "BYPASS")
            } else {
                return (.secondary, upper)
            }
        }()
        
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.12)))
    }
    
    private func copyAllHeaders(_ result: HTTPInspectionResult) {
        let text = result.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        copyToClipboard(text, toast: "All Headers Copied")
    }
}
