import SwiftUI

// MARK: - DNSDigToolView

struct DNSDigToolView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    @State private var queryMode = 0 // 0: Single (1.1.1.1), 1: Benchmark
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Query Configuration Card
                    configCard
                    
                    // 2. Results
                    if queryMode == 0 {
                        singleQueryResultsView
                    } else {
                        benchmarkResultsView
                    }
                    
                    if let error = viewModel.dnsError {
                        errorCard(message: error)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.domainInput.isEmpty {
                    startQuery()
                }
            }
        }
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
                                HIGFeedback.success()
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
    
    // MARK: - 1. Config Card
    private var configCard: some View {
        VStack(spacing: 14) {
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
                    .font(.title3)
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
                    .accessibilityLabel("Clear domain")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            if queryMode == 0 {
                HStack(spacing: 10) {
                    Text("Type:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Record Type", selection: $viewModel.selectedRecordType) {
                        ForEach(viewModel.recordTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                    
                    Toggle("DNSSEC", isOn: $viewModel.dnssecEnabled)
                        .labelsHidden()
                    Text("DNSSEC")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                isFieldFocused = false
                HIGFeedback.impact(.light)
                startQuery()
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isDnsLoading || viewModel.isBenchmarkLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                        Text("Query Resolvers")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isDnsLoading || viewModel.isBenchmarkLoading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - 2. Single Query Results
    @ViewBuilder
    private var singleQueryResultsView: some View {
        if viewModel.isDnsLoading {
            VStack(alignment: .leading, spacing: 12) {
                Text("Querying 1.1.1.1 Edge Resolvers...")
                    .font(.headline)
                Divider()
                ForEach(DNSAnswerItem.placeholders) { item in
                    DNSAnswerRowView(item: item)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .redacted(reason: .placeholder)
        } else if let result = viewModel.dnsResult {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Resolved Answers (\(result.answers.count))")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Cloudflare 1.1.1.1 Anycast Engine")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if result.isDNSSECValidated {
                        HIGBadge(.custom(color: .green, text: "DNSSEC"), isCompact: true)
                    }
                    HIGBadge(.custom(color: .blue, text: String(format: "%.1f ms", result.latencyMs)), isCompact: true)
                }
                
                Divider()
                
                if result.answers.isEmpty {
                    Text("No DNS records found for this query.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(result.answers) { item in
                            DNSAnswerRowView(item: item)
                        }
                    }
                }
                
                Divider()
                
                Button {
                    HIGFeedback.impact(.light)
                    viewModel.showingRFCExport = true
                } label: {
                    Label("View Raw RFC 1035 Output", systemImage: "terminal")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - 3. Benchmark Results
    @ViewBuilder
    private var benchmarkResultsView: some View {
        if viewModel.isBenchmarkLoading {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Benchmarking Public Resolvers...")
                        .font(.headline)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else if let result = viewModel.benchmarkResult, !result.items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Resolver Latency Comparison")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Ranked by lowest response time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                
                Divider()
                
                VStack(spacing: 10) {
                    ForEach(Array(result.items.enumerated()), id: \.element.id) { index, item in
                        benchmarkRow(item, rank: index + 1)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                Text(item.resolverName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(item.resolverIP)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if item.status == "OK", let lat = item.latencyMs {
                HIGBadge(.custom(color: rank == 1 ? .green : .blue, text: String(format: "%.1f ms", lat)), isCompact: true)
            } else {
                HIGBadge(.custom(color: .red, text: "TIMEOUT"), isCompact: true)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Query Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            
            Text(item.data)
                .font(.body.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Text("TTL \(item.ttl)s")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
