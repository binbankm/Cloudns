import SwiftUI

struct DNSDigToolView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    @State private var queryMode = 0 // 0: Single (1.1.1.1), 1: Benchmark
    
    var body: some View {
        List {
            // Mode Selector
            Section {
                Picker("Query Mode", selection: $queryMode) {
                    Text("1.1.1.1 Edge Query").tag(0)
                    Text("Multi-Resolver Benchmark").tag(1)
                }
                .pickerStyle(.segmented)
            }
            
            // MARK: - Target Domain & Type
            Section(header: Text("Query Target")) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("e.g. example.com", text: $viewModel.domainInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            startQuery()
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
                    startQuery()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isDnsLoading || viewModel.isBenchmarkLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: queryMode == 0 ? "magnifyingglass" : "speedometer")
                        }
                        Text(queryMode == 0 ? "Dig DNS Query (1.1.1.1)" : "Benchmark All Resolvers")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
                .disabled(viewModel.domainInput.isEmpty || viewModel.isDnsLoading || viewModel.isBenchmarkLoading)
            }
            
            // Mode 0: Single Query Results
            if queryMode == 0 {
                if viewModel.isDnsLoading {
                    Section(header: Text("Querying 1.1.1.1 Edge Resolvers...")) {
                        ForEach(DNSAnswerItem.placeholders) { item in
                            DNSAnswerRowView(item: item)
                        }
                        .skeletonLoading(true)
                    }
                } else if let result = viewModel.dnsResult {
                    Section(header: HStack {
                        Text("Resolved Answers (\(result.answers.count))")
                        Spacer()
                        if result.isDNSSECValidated {
                            CloudnsBadge(.active("DNSSEC Validated"), isCompact: true)
                        }
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
                    
                    Section {
                        Button {
                            viewModel.showingRFCExport = true
                        } label: {
                            Label("View RFC BIND Terminal Output", systemImage: "terminal")
                                .font(.subheadline)
                        }
                    }
                }
            } else {
                // Mode 1: Benchmark Results
                if viewModel.isBenchmarkLoading {
                    Section(header: Text("Benchmarking 5 Global Public Resolvers...")) {
                        ForEach(0..<5, id: \.self) { _ in
                            HStack {
                                Circle().fill(Color.gray.opacity(0.3)).frame(width: 24, height: 24)
                                Text("Cloudflare 1.1.1.1")
                                Spacer()
                                Text("12.4 ms")
                            }
                        }
                    }
                    .skeletonLoading(true)
                } else if let bench = viewModel.benchmarkResult {
                    Section(header: Text("Resolver Latency & Accuracy Benchmark")) {
                        ForEach(bench.items) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: item.icon)
                                        .foregroundStyle(item.color)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.resolverName)
                                            .font(.subheadline.weight(.semibold))
                                        Text(item.resolverIP)
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if item.isFastest {
                                        CloudnsBadge(.active("Fastest"), isCompact: true)
                                    }
                                    
                                    if let lat = item.latencyMs {
                                        Text(String(format: "%.1f ms", lat))
                                            .font(.subheadline.weight(.bold).monospacedDigit())
                                            .foregroundStyle(lat < 30 ? .green : (lat < 80 ? .orange : .red))
                                    } else {
                                        Text("Timeout")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                                
                                if !item.resolvedRecords.isEmpty {
                                    Text(item.resolvedRecords.joined(separator: ", "))
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .padding(.leading, 32)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            if let error = viewModel.dnsError {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("DNS Dig Query")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showingRFCExport) {
            if let result = viewModel.dnsResult {
                NavigationStack {
                    ScrollView {
                        Text(result.rawResponseRFC)
                            .font(.footnote.monospaced())
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("RFC BIND Output")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { viewModel.showingRFCExport = false }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                UIPasteboard.general.string = result.rawResponseRFC
                                HapticManager.notification(.success)
                                ToastManager.shared.showCopied("BIND Output copied")
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func startQuery() {
        Task {
            if queryMode == 0 {
                await viewModel.queryDNS()
            } else {
                await viewModel.runDNSBenchmark()
            }
        }
    }
}
