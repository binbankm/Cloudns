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
                        .font(.body)
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
                        HapticManager.impact(.light)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.body)
                            .foregroundStyle(Color.accentColor)
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
                            .buttonStyle(.plain)
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
                    HStack(spacing: 6) {
                        Spacer()
                        if viewModel.isTesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text("Send Test Request")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(viewModel.targetUrl.isEmpty || viewModel.isTesting ? Color(.tertiaryLabel) : Color.accentColor)
                }
                .disabled(viewModel.targetUrl.isEmpty || viewModel.isTesting)
            }
            
            // MARK: - Response Display
            if let status = viewModel.responseStatusCode {
                Section {
                    HStack {
                        Text("HTTP Status")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        let statusText = [String(status), viewModel.responseStatusText].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
                        let isSuccess = (200...299).contains(status)
                        Text(statusText)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(isSuccess ? Color.green : Color.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill((isSuccess ? Color.green : Color.red).opacity(0.12)))
                    }
                    
                    if let dur = viewModel.responseDurationMs {
                        HStack {
                            Text("Latency / Time")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(dur.formatted(.number.precision(.fractionLength(1)))) ms")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green.opacity(0.12)))
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
                                .padding(8)
                                .textSelection(.enabled)
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } header: {
                        HStack {
                            Text("Response Payload")
                            Spacer()
                            Button {
                                copyToClipboard(body, toast: "Response Copied")
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else if let err = viewModel.errorMessage {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                        Text(verbatim: err)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Error")
                }
            } else {
                // Ready Guide Banner
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.horizontal.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor.opacity(0.8))
                            .accessibilityHidden(true)
                        
                        Text("Ready to Probe Worker")
                            .font(.subheadline.weight(.semibold))
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
        .navigationTitle("Test Dispatch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        let curl = generateCurlCommand()
                        copyToClipboard(curl, toast: "cURL Command Copied")
                    } label: {
                        Label("Copy as cURL", systemImage: "terminal")
                    }
                    
                    Button {
                        let fetchCode = generateFetchCode()
                        copyToClipboard(fetchCode, toast: "Fetch Code Copied")
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
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
