import SwiftUI

struct HTTPHeaderInspectorView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Section: URL Input
            Section(header: Text("Target URL")) {
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
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
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Clear input")
                    }
                }
                
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
                        Text("Inspect HTTP & Edge Headers")
                            .font(.body)
                        Spacer()
                    }
                }
                .disabled(viewModel.httpUrlInput.isEmpty || viewModel.isHttpLoading)
            }
            
            if viewModel.isHttpLoading {
                httpResultSections(HTTPInspectionResult.placeholder)
                    .skeletonLoading(true)
            } else if let result = viewModel.httpResult {
                httpResultSections(result)
            } else if let error = viewModel.httpError {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.25), value: viewModel.httpResult == nil)
        .navigationTitle("HTTP Header Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func httpResultSections(_ result: HTTPInspectionResult) -> some View {
        Section(header: Text("Response Overview")) {
            HStack {
                Text("Status Code")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(result.statusCode)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(result.statusCode < 400 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .foregroundStyle(result.statusCode < 400 ? .green : .red)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            HStack {
                Text("Response Latency")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f ms", result.durationMs))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            if let ray = result.cfRay {
                HStack {
                    Text("CF-Ray ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ray)
                        .font(.caption.monospaced())
                        .foregroundStyle(.orange)
                }
            }
            
            if let cache = result.cfCacheStatus {
                HStack {
                    Text("CF-Cache-Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(cache)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        
        // Section: Response Headers
        Section(header: HStack {
            Text("Response Headers (\(result.headers.count))")
            Spacer()
            Button {
                let text = result.headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                UIPasteboard.general.string = text
                HapticManager.notification(.success)
                ToastManager.shared.showCopied("Headers copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .accessibilityLabel("Copy all headers")
        }) {
            ForEach(result.headers) { header in
                VStack(alignment: .leading, spacing: 3) {
                    Text(header.key)
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(header.value)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 2)
            }
        }
    }
}
