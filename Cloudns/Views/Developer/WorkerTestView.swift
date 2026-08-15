import SwiftUI

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
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            List {
                // Section 1: Target URL & Method
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
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Target URL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(.orange)
                            
                            TextField("https://...", text: $viewModel.targetUrl)
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
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    
                    // Quick Path Shortcuts
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickPathButton("/")
                            quickPathButton("/api")
                            quickPathButton("/health")
                            quickPathButton("/json")
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Request Configuration")
                }
                
                // Section 2: Request Payload (if POST/PUT/PATCH)
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
                
                // Section 3: Dispatch Action
                Section {
                    Button {
                        isFieldFocused = false
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
                                .font(.body)
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.targetUrl.isEmpty || viewModel.isTesting)
                }
                
                // Section 4: Response Display
                if let status = viewModel.responseStatusCode {
                    Section {
                        HStack {
                            Text("Status Code")
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill((200...299).contains(status) ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text("\(status) \(viewModel.responseStatusText ?? "")")
                                    .font(.body)
                                    .foregroundStyle((200...299).contains(status) ? .green : .orange)
                            }
                        }
                        
                        if let dur = viewModel.responseDurationMs {
                            HStack {
                                Text("Latency / Time")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.1f ms", dur))
                                    .font(.caption)
                                    .foregroundStyle(.green)
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
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                        } header: {
                            HStack {
                                Text("Response Payload")
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = body
                                    ToastManager.shared.showCopied("Response body copied")
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
                                .font(.system(size: 38))
                                .foregroundStyle(.orange.opacity(0.8))
                            
                            Text("Ready to Probe Worker")
                                .font(.subheadline)
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
        }
        .navigationTitle("Test Dispatch")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func quickPathButton(_ path: String) -> some View {
        Button {
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
                .cornerRadius(6)
        }
    }
}
