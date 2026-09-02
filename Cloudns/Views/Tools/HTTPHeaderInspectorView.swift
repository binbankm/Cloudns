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
            Section(header: Text("Request Configuration"), footer: Text("Inspects live Cloudflare Edge HTTP response status, CF-Ray, caching status & custom headers.")) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "link")
                        .font(HIGTypography.body)
                        .foregroundStyle(Color.higAccent)
                        .accessibilityHidden(true)
                    
                    TextField("https://example.com", text: $viewModel.httpUrlInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(HIGTypography.body.monospacedDigit())
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
                        .higTouchTarget(44)
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
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        if viewModel.isHttpLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.up.right.circle.fill")
                        }
                        Text(viewModel.isHttpLoading ? "Connecting Edge…" : "Inspect Edge Response")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.httpUrlInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isHttpLoading ? Color(.tertiaryLabel) : Color.higAccent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.higPressable)
                .disabled(viewModel.httpUrlInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isHttpLoading)
            }
            
            if viewModel.isHttpLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Inspecting Edge Response…")
                            .font(HIGTypography.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, HIGTokens.Spacing.sm)
                }
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
                    .higTouchTarget(44)
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
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: HIGTokens.Spacing.xs) {
                Text("\(result.statusCode)")
                    .font(HIGTypography.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(result.statusCode < 400 ? HIGColors.success : HIGColors.error)
                Text(result.statusText)
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        
        if let cache = result.cfCacheStatus {
            HStack {
                Text("CF-Cache-Status")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                cacheStatusBadge(cache)
            }
        }
        
        if let ray = result.cfRay {
            HStack {
                Text("CF-Ray ID")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(ray)
                    .font(HIGTypography.subheadline.monospaced())
                    .foregroundStyle(.primary)
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = ray
                    ToastManager.shared.showCopied("CF-Ray Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy CF-Ray ID", systemImage: "doc.on.doc")
                }
            }
        }
        
        HStack {
            Text("Total TTFB Latency")
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(result.durationMs.formatted(.number.precision(.fractionLength(1)))) ms")
                .font(HIGTypography.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
    
    @ViewBuilder
    private func headersRows(result: HTTPInspectionResult) -> some View {
        ForEach(filteredHeaders) { header in
            HStack(alignment: .top, spacing: HIGTokens.Spacing.sm) {
                Text(header.key)
                    .font(HIGTypography.caption.monospaced().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 120, alignment: .leading)
                
                Text(header.value)
                    .font(HIGTypography.caption.monospaced())
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = "\(header.key): \(header.value)"
                    ToastManager.shared.showCopied("Header Copied")
                    HIGFeedback.copied()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.higPressable)
                .higTouchTarget(44)
            }
            .padding(.vertical, HIGTokens.Spacing.xxs)
            .contextMenu {
                Button {
                    UIPasteboard.general.string = "\(header.key): \(header.value)"
                    ToastManager.shared.showCopied("Header Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy Line", systemImage: "doc.on.doc")
                }
                Button {
                    UIPasteboard.general.string = header.value
                    ToastManager.shared.showCopied("Value Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy Value", systemImage: "text.alignleft")
                }
            }
        }
    }
    
    @ViewBuilder
    private func cacheStatusBadge(_ status: String) -> some View {
        let upper = status.uppercased()
        if upper.contains("HIT") {
            HIGBadge(.active("HIT"), isCompact: true)
        } else if upper.contains("MISS") {
            HIGBadge(.warning("MISS"), isCompact: true)
        } else if upper.contains("DYNAMIC") {
            HIGBadge(.proxied("DYNAMIC"), isCompact: true)
        } else if upper.contains("BYPASS") {
            HIGBadge(.dnsOnly("BYPASS"), isCompact: true)
        } else {
            HIGBadge(.custom(color: .secondary, text: upper), isCompact: true)
        }
    }
    
    private func copyAllHeaders(_ result: HTTPInspectionResult) {
        let text = result.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        ToastManager.shared.showCopied("All Headers Copied")
        HIGFeedback.copied()
    }
}
