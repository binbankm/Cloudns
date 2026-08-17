import SwiftUI

struct DNSDigToolView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Section: Input & Type
            Section(header: Text("Query Target")) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("e.g. example.com", text: $viewModel.domainInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.queryDNS() }
                        }
                    
                    if !viewModel.domainInput.isEmpty {
                        Button {
                            viewModel.domainInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Clear input")
                    }
                }
                
                Picker("Record Type", selection: $viewModel.selectedRecordType) {
                    ForEach(viewModel.recordTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                
                Button {
                    isFieldFocused = false
                    HapticManager.impact(.light)
                    Task { await viewModel.queryDNS() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isDnsLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text("Dig DNS Query (1.1.1.1)")
                            .font(.body)
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
                .disabled(viewModel.domainInput.isEmpty || viewModel.isDnsLoading)
            }
            
            // Section: Results
            if let result = viewModel.dnsResult {
                Section(header: HStack {
                    Text("Resolved Answers (\(result.answers.count))")
                    Spacer()
                    CloudnsBadge(.active(String(format: "%.1f ms", result.latencyMs)), isCompact: true)
                }) {
                    if result.answers.isEmpty {
                        Text("No DNS records found for this domain and type.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(result.answers) { item in
                            DNSAnswerRowView(item: item)
                        }
                    }
                }
            } else if let error = viewModel.dnsError {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("DNS Dig Query")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DNSAnswerRowView: View {
    let item: DNSAnswerItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(item.typeName)
                    .font(.caption.monospacedDigit())
                    .frame(width: 48)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(item.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(item.ttl)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(item.data)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = item.data
                HapticManager.notification(.success)
                ToastManager.shared.showCopied("Record data copied")
            } label: {
                Label("Copy Record Data", systemImage: "doc.on.doc")
            }
        }
    }
}
