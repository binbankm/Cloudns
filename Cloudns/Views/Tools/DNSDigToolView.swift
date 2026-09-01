import SwiftUI

// MARK: - DNSDigToolView

struct DNSDigToolView: View {
    @StateObject private var viewModel = DNSDigViewModel()
    @FocusState private var isFieldFocused: Bool
    @State private var queryMode = 0 // 0: Single (1.1.1.1), 1: Benchmark
    
    var body: some View {
        List {
            // 1. Query Configuration Section
            Section(header: Text("Query Configuration"), footer: Text("Queries 1.1.1.1 Anycast edge resolver with optional DNSSEC verification or benchmarks worldwide public resolvers.")) {
                Picker("Query Mode", selection: $queryMode) {
                    Text("1.1.1.1 Edge Query").tag(0)
                    Text("Multi-Resolver Benchmark").tag(1)
                }
                .pickerStyle(.segmented)
                .onChange(of: queryMode) { _ in
                    HIGFeedback.selection()
                }
                
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("e.g. example.com", text: $viewModel.domainInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(.body.monospacedDigit())
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
                        .buttonStyle(.plain)
                        .higTouchTarget(36)
                        .accessibilityLabel("Clear Domain")
                    }
                }
                
                if queryMode == 0 {
                    HStack {
                        Text("Record Type")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Picker("Record Type", selection: $viewModel.selectedRecordType) {
                            ForEach(viewModel.recordTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    
                    Toggle("DNSSEC Validation", isOn: $viewModel.dnssecEnabled)
                }
                
                Button {
                    isFieldFocused = false
                    HIGFeedback.impact(.light)
                    startQuery()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isDnsLoading || viewModel.isBenchmarkLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(viewModel.isDnsLoading || viewModel.isBenchmarkLoading ? "Querying Resolvers…" : (queryMode == 0 ? "Query 1.1.1.1 Resolver" : "Benchmark 5 Resolvers"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.higPressable)
                .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isDnsLoading || viewModel.isBenchmarkLoading)
            }
            
            // 2. Results Sections
            if queryMode == 0 {
                if viewModel.isDnsLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Resolving DNS Records…")
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } else if let result = viewModel.dnsResult {
                    Section(header: Text("Resolved Answers (\(result.answers.count))")) {
                        HStack {
                            Text("Resolver Engine")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if result.isDNSSECValidated {
                                HIGBadge(.custom(color: .green, text: "DNSSEC Validated"), isCompact: true)
                            }
                            HIGBadge(.custom(color: .blue, text: "\(result.latencyMs.formatted(.number.precision(.fractionLength(1)))) ms"), isCompact: true)
                        }
                        
                        if result.answers.isEmpty {
                            Text("No DNS records found for this query.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(result.answers) { item in
                                DNSAnswerRowView(item: item)
                            }
                        }
                        
                        Button {
                            HIGFeedback.impact(.light)
                            viewModel.showingRFCExport = true
                        } label: {
                            Label("View Raw RFC 1035 Output", systemImage: "terminal")
                                .font(.subheadline)
                        }
                    }
                }
            } else {
                if viewModel.isBenchmarkLoading {
                    Section(header: Text("Benchmarking Public Resolvers…")) {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Probing Cloudflare, Google, Quad9, OpenDNS…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let result = viewModel.benchmarkResult, !result.items.isEmpty {
                    Section(header: Text("Resolver Latency Comparison"), footer: Text("Ranked by lowest response time.")) {
                        ForEach(Array(result.items.enumerated()), id: \.element.id) { index, item in
                            benchmarkRow(item, rank: index + 1)
                        }
                    }
                }
            }
            
            if let error = viewModel.dnsError {
                Section(header: Text("Error")) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(verbatim: error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            if !viewModel.domainInput.isEmpty {
                startQuery()
            }
        }
        .navigationTitle("DNS Dig Query")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showingRFCExport) {
            Group {
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
                                    HIGFeedback.copied()
                                    UIPasteboard.general.string = result.rawResponseRFC
                                    ToastManager.shared.showCopied()
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .accessibilityLabel("Copy RFC Output")
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .higToast()
        }
    }
    
    @ViewBuilder
    private func benchmarkRow(_ item: DNSBenchmarkItem, rank: Int? = nil) -> some View {
        HStack(spacing: 12) {
            if let rank = rank {
                Text("\(rank)")
                    .font(.callout.bold().monospacedDigit())
                    .foregroundStyle(rank == 1 ? Color.yellow : Color.secondary)
                    .frame(width: 20)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.resolverName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(verbatim: item.resolverIP)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if item.status == "OK", let lat = item.latencyMs {
                HIGBadge(.custom(color: rank == 1 ? .green : .blue, text: "\(lat.formatted(.number.precision(.fractionLength(1)))) ms"), isCompact: true)
            } else {
                HIGBadge(.custom(color: .red, text: "TIMEOUT"), isCompact: true)
            }
        }
        .padding(.vertical, 2)
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

// MARK: - DNSAnswerRowView (Inlined & Cohesive)

struct DNSAnswerRowView: View {
    let item: DNSAnswerItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            HIGBadge(.custom(color: .indigo, text: item.typeName), isCompact: true)
            
            Text(verbatim: item.data)
                .font(.body.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Text("TTL \(item.ttl)s")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            
            Button {
                HIGFeedback.copied()
                UIPasteboard.general.string = item.data
                ToastManager.shared.showCopied()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.higPressable)
            .higTouchTarget()
            .accessibilityLabel("Copy \(item.typeName) record: \(item.data)")
        }
        .padding(.vertical, 4)
    }
}
