import SwiftUI

struct WorkerTestView: View {
    // MARK: - Properties
    let scriptName: String
    let initialRoute: String?
    @StateObject private var viewModel: WorkerTesterViewModel
    @FocusState private var isFieldFocused: Bool
    
    init(scriptName: String, initialRoute: String? = nil) {
        self.scriptName = scriptName
        self.initialRoute = initialRoute
        _viewModel = StateObject(wrappedValue: WorkerTesterViewModel(scriptName: scriptName, initialRoute: initialRoute))
    }
    
    // MARK: - Body
    var body: some View {
        List {
            // MARK: - Target URL & Method
            Section {
                HStack {
                    Text("HTTP Method")
                        .foregroundStyle(.primary)
                    Spacer()
                    Picker("Method", selection: $viewModel.selectedMethod) {
                        ForEach(viewModel.methods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.selectedMethod) { _ in
                        HapticManager.impact(.light)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        
                        TextField("https://...", text: $viewModel.targetUrl)
                            .submitLabel(.done)
                            .font(.body.monospacedDigit())
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
                            .accessibilityLabel("Clear URL")
                        }
                    }
                }
                .padding(.vertical, 2)
                
                // Quick Path Shortcuts
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        quickPathButton("/")
                        quickPathButton("/api")
                        quickPathButton("/health")
                        quickPathButton("/json")
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            } header: {
                Text("Request Configuration")
            }
            
            // MARK: - Request Payload (if POST/PUT/PATCH)
            if viewModel.selectedMethod == "POST" || viewModel.selectedMethod == "PUT" || viewModel.selectedMethod == "PATCH" {
                Section {
                    TextEditor(text: $viewModel.requestBody)
                        .font(.caption.monospacedDigit())
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
                    HapticManager.impact(.medium)
                    Task { await viewModel.executeDispatch() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isTesting {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text("Send Test Request")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                }
                .disabled(viewModel.targetUrl.isEmpty || viewModel.isTesting)
            }
            
            // MARK: - Response Display
            if let status = viewModel.responseStatusCode {
                Section {
                    HStack {
                        Text("HTTP Status")
                            .foregroundStyle(.secondary)
                        Spacer()
                        CloudnsBadge((200...299).contains(status) ? .active("\(status) \(viewModel.responseStatusText ?? "")") : .error("\(status) \(viewModel.responseStatusText ?? "")"), isCompact: true)
                    }
                    
                    if let dur = viewModel.responseDurationMs {
                        HStack {
                            Text("Latency / Time")
                                .foregroundStyle(.secondary)
                            Spacer()
                            CloudnsBadge(.active(String(format: "%.1f ms", dur)), isCompact: true)
                        }
                    }
                } header: {
                    Text("Response Status")
                }
                
                if let body = viewModel.responseBody, !body.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(body)
                                .font(.caption.monospacedDigit())
                                .padding(10)
                                .textSelection(.enabled)
                        }
                        .background(CloudnsColor.secondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                    } header: {
                        HStack {
                            Text("Response Payload")
                            Spacer()
                            Button {
                                UIPasteboard.general.string = body
                                HapticManager.notification(.success)
                                CloudnsToastManager.shared.showCopied("Response body copied")
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else if let err = viewModel.errorMessage {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                        Text(err)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Error")
                }
            } else {
                // Ready Guide Banner
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "bolt.horizontal.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange.opacity(0.8))
                            .accessibilityHidden(true)
                        
                        Text("Ready to Probe Worker")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        Text("Send live HTTP requests directly from your device to test edge routing, response headers, and latency in real time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Test Dispatch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        let curl = generateCurlCommand()
                        UIPasteboard.general.string = curl
                        HapticManager.notification(.success)
                        CloudnsToastManager.shared.showCopied("cURL command copied")
                    } label: {
                        Label("Copy as cURL", systemImage: "terminal")
                    }
                    
                    Button {
                        let fetchCode = generateFetchCode()
                        UIPasteboard.general.string = fetchCode
                        HapticManager.notification(.success)
                        CloudnsToastManager.shared.showCopied("Fetch (TS) code copied")
                    } label: {
                        Label("Copy as Fetch (TS)", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.targetUrl.isEmpty)
                .accessibilityLabel("Export Request")
            }
        }
    }
    
    // MARK: - Actions
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
    
    // MARK: - Private Views
    private func quickPathButton(_ path: String) -> some View {
        Button {
            HapticManager.impact(.light)
            if let url = URL(string: viewModel.targetUrl) {
                var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                comps?.path = path
                if let newUrl = comps?.url?.absoluteString {
                    viewModel.targetUrl = newUrl
                }
            }
        } label: {
            Text(path)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
