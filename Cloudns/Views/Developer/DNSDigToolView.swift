import SwiftUI

struct DNSDigToolView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            List {
                // Section: Input & Type
                Section(header: Text("Query Target")) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        
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
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Picker("Record Type", selection: $viewModel.selectedRecordType) {
                        ForEach(viewModel.recordTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    Button {
                        isFieldFocused = false
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
                            Text("Dig Query (1.1.1.1)")
                                .font(.body.weight(.semibold))
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
                        Text(String(format: "%.1f ms", result.latencyMs))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                    }) {
                        if result.answers.isEmpty {
                            Text("No DNS records returned for this query.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
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
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .frame(width: 48)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
                Text(item.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(item.ttl)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(item.data)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = item.data
                ToastManager.shared.showCopied("Record data copied")
            } label: {
                Label("Copy Record Data", systemImage: "doc.on.doc")
            }
        }
    }
}
