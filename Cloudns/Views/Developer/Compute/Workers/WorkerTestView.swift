import SwiftUI

// MARK: - WorkerTestView
// Apple HIG Compliant Edge Request Dispatcher, Payload Tester & cURL Generator

struct WorkerTestView: View {
    let scriptName: String
    let initialRoute: String?
    @StateObject private var viewModel: WorkerTesterViewModel
    @FocusState private var isFieldFocused: Bool
    
    init(scriptName: String, initialRoute: String? = nil) {
        self.scriptName = scriptName
        self.initialRoute = initialRoute
        _viewModel = StateObject(wrappedValue: WorkerTesterViewModel(scriptName: scriptName, initialRoute: initialRoute))
    }
    
    var body: some View {
        List {
            // MARK: - Target URL & Method
            Section {
                HStack {
                    Text("HTTP Method")
                        .font(HIGTypography.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker("Method", selection: $viewModel.selectedMethod) {
                        ForEach(viewModel.methods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: viewModel.selectedMethod) { _ in
                        HIGFeedback.impact(.light)
                    }
                }
                
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                    Text("Target URL")
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "link")
                            .font(HIGTypography.body)
                            .foregroundStyle(Color.higAccent)
                            .accessibilityHidden(true)
                        
                        TextField("https://...", text: $viewModel.targetUrl)
                            .submitLabel(.done)
                            .font(HIGTypography.body.monospacedDigit())
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .focused($isFieldFocused)
                        
                        if !viewModel.targetUrl.isEmpty {
                            Button {
                                viewModel.targetUrl = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .higTouchTarget(44)
                            .accessibilityLabel("Clear URL")
                        }
                    }
                }
                .padding(.vertical, HIGTokens.Spacing.xxs)
                
                // Quick Path Shortcuts
                ScrollView(.horizontal) {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        quickPathButton("/")
                        quickPathButton("/api")
                        quickPathButton("/health")
                        quickPathButton("/json")
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                }
                .scrollIndicators(.hidden)
            } header: {
                Text("Request Configuration")
            }
            
            // MARK: - Request Payload (if POST/PUT/PATCH)
            if viewModel.selectedMethod == "POST" || viewModel.selectedMethod == "PUT" || viewModel.selectedMethod == "PATCH" {
                Section {
                    TextEditor(text: $viewModel.requestBody)
                        .font(HIGTypography.caption.monospacedDigit())
                        .frame(minHeight: 90)
                } header: {
                    Text("Request Body (JSON)")
                } footer: {
                    Text("Custom JSON payload sent in the HTTP request body.")
                }
            }
            
            // MARK: - Dispatch Action
            Section {
                Button {
                    isFieldFocused = false
                    HIGFeedback.impact(.medium)
                    Task { await viewModel.executeDispatch() }
                } label: {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Spacer()
                        if viewModel.isTesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text("Send Test Request")
                            .font(HIGTypography.body.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(viewModel.targetUrl.isEmpty || viewModel.isTesting ? Color(.tertiaryLabel) : Color.higAccent)
                }
                .buttonStyle(.higPressable)
                .disabled(viewModel.targetUrl.isEmpty || viewModel.isTesting)
            }
            
            // MARK: - Response Display
            if let status = viewModel.responseStatusCode {
                Section {
                    HStack {
                        Text("HTTP Status")
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        let statusText = [String(status), viewModel.responseStatusText].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
                        HIGBadge(.custom(color: (200...299).contains(status) ? HIGColors.success : HIGColors.error, text: statusText), isCompact: true)
                    }
                    
                    if let dur = viewModel.responseDurationMs {
                        HStack {
                            Text("Latency / Time")
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HIGBadge(.custom(color: HIGColors.success, text: "\(dur.formatted(.number.precision(.fractionLength(1)))) ms"), isCompact: true)
                        }
                    }
                } header: {
                    Text("Response Status")
                }
                
                if let body = viewModel.responseBody, !body.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(body)
                                .font(HIGTypography.caption.monospacedDigit())
                                .padding(HIGTokens.Spacing.sm)
                                .textSelection(.enabled)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                    } header: {
                        HStack {
                            Text("Response Payload")
                            Spacer()
                            Button {
                                UIPasteboard.general.string = body
                                ToastManager.shared.showCopied("Response Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(HIGTypography.caption)
                            }
                            .buttonStyle(.higPressable)
                            .higTouchTarget(44)
                        }
                    }
                }
            } else if let err = viewModel.errorMessage {
                Section {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HIGColors.error)
                            .accessibilityHidden(true)
                        Text(verbatim: err)
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(HIGColors.error)
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                } header: {
                    Text("Error")
                }
            } else {
                // Ready Guide Banner
                Section {
                    VStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "bolt.horizontal.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.higAccent.opacity(0.8))
                            .accessibilityHidden(true)
                        
                        Text("Ready to Probe Worker")
                            .font(HIGTypography.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Send live HTTP requests directly from your device to test edge routing, response headers, and latency in real time.")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, HIGTokens.Spacing.md)
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Test Dispatch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        let curl = generateCurlCommand()
                        UIPasteboard.general.string = curl
                        ToastManager.shared.showCopied("cURL Command Copied")
                        HIGFeedback.copied()
                    } label: {
                        Label("Copy as cURL", systemImage: "terminal")
                    }
                    
                    Button {
                        let fetchCode = generateFetchCode()
                        UIPasteboard.general.string = fetchCode
                        ToastManager.shared.showCopied("Fetch Code Copied")
                        HIGFeedback.copied()
                    } label: {
                        Label("Copy as Fetch (TS)", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.targetUrl.isEmpty)
                .accessibilityLabel("Export Request")
                .higTouchTarget(44)
            }
        }
    }
    
    private func generateCurlCommand() -> String {
        var parts: [String] = ["curl -X \(viewModel.selectedMethod) \"\(viewModel.targetUrl)\""]
        if viewModel.selectedMethod == "POST" || viewModel.selectedMethod == "PUT" || viewModel.selectedMethod == "PATCH" {
            parts.append("-H \"Content-Type: application/json\"")
            if !viewModel.requestBody.isEmpty {
                let escaped = viewModel.requestBody.replacingOccurrences(of: "\"", with: "\\\"")
                parts.append("-d \"\(escaped)\"")
            }
        }
        return parts.joined(separator: " \\\n  ")
    }
    
    private func generateFetchCode() -> String {
        var options: [String] = ["method: '\(viewModel.selectedMethod)'"]
        if viewModel.selectedMethod == "POST" || viewModel.selectedMethod == "PUT" || viewModel.selectedMethod == "PATCH" {
            options.append("headers: { 'Content-Type': 'application/json' }")
            if !viewModel.requestBody.isEmpty {
                options.append("body: JSON.stringify(\(viewModel.requestBody))")
            }
        }
        return """
        const response = await fetch('\(viewModel.targetUrl)', {
          \(options.joined(separator: ",\n  "))
        });
        const data = await response.json();
        console.log(data);
        """
    }
    
    private func quickPathButton(_ path: String) -> some View {
        Button {
            HIGFeedback.impact(.light)
            if let url = URL(string: viewModel.targetUrl) {
                var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                comps?.path = path
                if let newUrl = comps?.url?.absoluteString {
                    viewModel.targetUrl = newUrl
                }
            }
        } label: {
            Text(path)
                .font(HIGTypography.caption2.monospacedDigit())
                .foregroundStyle(Color.higAccent)
                .padding(.horizontal, HIGTokens.Spacing.sm + 2)
                .padding(.vertical, HIGTokens.Spacing.xxs + 2)
                .background(Color.higAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.sm, style: .continuous))
        }
        .buttonStyle(.higPressable)
    }
}
