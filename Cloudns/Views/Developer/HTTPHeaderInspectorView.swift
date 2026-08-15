import SwiftUI

struct HTTPHeaderInspectorView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            List {
                // Section: URL Input
                Section(header: Text("Target URL")) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        
                        TextField("https://example.com", text: $viewModel.httpUrlInput)
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
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        isFieldFocused = false
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
                            Text("Inspect HTTP Headers")
                                .font(.body)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.httpUrlInput.isEmpty || viewModel.isHttpLoading)
                }
                
                // Section: Response Summary
                if let result = viewModel.httpResult {
                    Section(header: Text("Response Overview")) {
                        HStack {
                            Text("Status Code")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(result.statusCode) \(result.statusText)")
                                .font(.body)
                                .foregroundColor((200...299).contains(result.statusCode) ? .green : .orange)
                        }
                        
                        HStack {
                            Text("Response Latency")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f ms", result.durationMs))
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if let cache = result.cfCacheStatus {
                            HStack {
                                Text("CF-Cache-Status")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(cache.uppercased())
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(cache.uppercased() == "HIT" ? .green : .orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background((cache.uppercased() == "HIT" ? Color.green : Color.orange).opacity(0.12))
                                    .cornerRadius(4)
                            }
                        }
                        
                        if let ray = result.cfRay {
                            HStack {
                                Text("CF-RAY")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(ray)
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // Section: All Headers Table
                    Section(header: HStack {
                        Text("All Headers (\(result.headers.count))")
                        Spacer()
                        Button {
                            let text = result.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                            UIPasteboard.general.string = text
                            ToastManager.shared.showCopied("Headers copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                    }) {
                        ForEach(result.headers) { h in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(h.key)
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.primary)
                                
                                Text(h.value)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } else if let error = viewModel.httpError {
                    Section {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("HTTP Header Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
}
