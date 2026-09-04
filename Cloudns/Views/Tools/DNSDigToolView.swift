import SwiftUI

// MARK: - DNSDigToolView
// Apple HIG Compliant 1.1.1.1 DNS Resolver Query & Global Benchmark

struct DNSDigToolView: View {
    @StateObject private var viewModel = DNSDigViewModel()
    @FocusState private var isFieldFocused: Bool
    @State private var queryMode = 0 // 0: Single (1.1.1.1), 1: Benchmark
    
    var body: some View {
        List {
            // 1. Query Configuration Section
            Section {
                Picker("Query Mode", selection: $queryMode) {
                    Text("1.1.1.1 Edge Query").tag(0)
                    Text("Multi-Resolver Benchmark").tag(1)
                }
                .pickerStyle(.segmented)
                .onChange(of: queryMode) { _ in
                    HapticManager.selection()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .foregroundStyle(.tint)
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
                    HapticManager.impact(.light)
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
                .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isDnsLoading || viewModel.isBenchmarkLoading)
            } header: {
                Text("Query Configuration")
            } footer: {
                Text("Queries 1.1.1.1 Anycast edge resolver with optional DNSSEC verification or benchmarks worldwide public resolvers.")
            }
            
            // 2. Results Sections
            if queryMode == 0 {
                if viewModel.isDnsLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Resolving DNS Records…")
                                .padding(.vertical, 8)
                            Spacer()
                        }
                    }
                } else if let result = viewModel.dnsResult {
                    Section("Resolved Answers (\(result.answers.count))") {
                        HStack {
                            Text("Resolver Engine")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if result.isDNSSECValidated {
                                Text("DNSSEC Validated")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.green.opacity(0.12)))
                            }
                            Text("\(result.latencyMs.formatted(.number.precision(.fractionLength(1)))) ms")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.tint)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor.opacity(0.12)))
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
                            HapticManager.impact(.light)
                            viewModel.showingRFCExport = true
                        } label: {
                            Label("View Raw RFC 1035 Output", systemImage: "terminal")
                                .font(.subheadline)
                        }
                    }
                }
            } else {
                if viewModel.isBenchmarkLoading {
                    Section("Benchmarking Public Resolvers…") {
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
                Section("Error") {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(verbatim: error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
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
                                .font(.caption.monospaced())
                                .padding(16)
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
                                    copyToClipboard(result.rawResponseRFC, toast: "RFC Output Copied")
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
        }
    }
    
    @ViewBuilder
    private func benchmarkRow(_ item: DNSBenchmarkItem, rank: Int? = nil) -> some View {
        HStack(spacing: 12) {
            if let rank = rank {
                Text("\(rank)")
                    .font(.body.weight(.bold).monospacedDigit())
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
                let badgeColor = rank == 1 ? Color.green : Color.accentColor
                Text("\(lat.formatted(.number.precision(.fractionLength(1)))) ms")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(badgeColor.opacity(0.12)))
            } else {
                Text("TIMEOUT")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                copyToClipboard(item.resolverIP, toast: "IP Copied")
            } label: {
                Label("Copy Resolver IP", systemImage: "doc.on.doc")
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

// MARK: - DNSAnswerRowView (Inlined & Cohesive)

struct DNSAnswerRowView: View {
    let item: DNSAnswerItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(item.typeName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.indigo)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.indigo.opacity(0.12)))
            
            Text(verbatim: item.data)
                .font(.body.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Text("TTL \(item.ttl)s")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            
            Button {
                copyToClipboard(item.data, toast: "Record Data Copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy \(item.typeName) record: \(item.data)")
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                copyToClipboard(item.data, toast: "Data Copied")
            } label: {
                Label("Copy Record Data", systemImage: "doc.on.doc")
            }
        }
    }
}
