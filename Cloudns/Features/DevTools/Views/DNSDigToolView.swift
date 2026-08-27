import SwiftUI

struct DNSDigToolView: View {
    // MARK: - Properties
    @StateObject private var viewModel = DevToolsViewModel()
    @ObservedObject private var historyManager = DevToolsHistoryManager.shared
    @FocusState private var isFieldFocused: Bool
    @State private var queryMode = 0 // 0: Single (1.1.1.1), 1: Benchmark
    
    // MARK: - Body
    var body: some View {
        ZStack {
            CloudnsColor.groupedBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: CloudnsSpacing.md) {
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
                .padding(.horizontal, CloudnsSpacing.md)
                .padding(.vertical, CloudnsSpacing.mdSmall)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.domainInput.isEmpty {
                    HapticManager.impact(.light)
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
                                HapticManager.notification(.success)
                                CloudnsToastManager.shared.showCopied("BIND Output copied")
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
        VStack(spacing: CloudnsSpacing.mdMedium) {
            Picker("Query Mode", selection: $queryMode) {
                Text("1.1.1.1 Edge Query").tag(0)
                Text("Multi-Resolver Benchmark").tag(1)
            }
            .pickerStyle(.segmented)
            
            HStack(spacing: CloudnsSpacing.smMd) {
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
                    .accessibilityLabel("Clear input")
                }
            }
            .padding(CloudnsSpacing.mdSmall)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            
            QueryHistoryChipsView(
                history: historyManager.dnsHistory,
                onSelect: { domain in
                    viewModel.domainInput = domain
                    startQuery()
                },
                onClear: {
                    historyManager.clearHistory(for: .dnsDig)
                }
            )
            
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
                }
            }
            
            CloudnsButton(
                queryMode == 0 ? "Dig DNS Query (1.1.1.1)" : "Benchmark Resolvers",
                icon: queryMode == 0 ? "magnifyingglass" : "speedometer",
                style: .primary(color: .blue),
                size: .regular,
                isFullWidth: true,
                isLoading: viewModel.isDnsLoading || viewModel.isBenchmarkLoading,
                disabled: viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                isFieldFocused = false
                startQuery()
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 2. Single Query Results
    @ViewBuilder
    private var singleQueryResultsView: some View {
        if viewModel.isDnsLoading {
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
                Text("Querying 1.1.1.1 Edge Resolvers...")
                    .font(.headline)
                Divider()
                ForEach(DNSAnswerItem.placeholders) { item in
                    DNSAnswerRowView(item: item)
                }
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
            .skeletonLoading(true)
        } else if let result = viewModel.dnsResult {
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdMedium) {
                HStack {
                    VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                        Text("Resolved Answers (\(result.answers.count))")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Cloudflare 1.1.1.1 Anycast Engine")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if result.isDNSSECValidated {
                        CloudnsBadge(.active("DNSSEC Validated"), isCompact: true)
                    }
                    CloudnsBadge(.active(String(format: "%.1f ms", result.latencyMs)), isCompact: true)
                }
                
                Divider()
                
                if result.answers.isEmpty {
                    Text("No DNS records found for this query.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, CloudnsSpacing.sm)
                } else {
                    VStack(spacing: CloudnsSpacing.sm) {
                        ForEach(result.answers) { item in
                            DNSAnswerRowView(item: item)
                        }
                    }
                }
                
                Divider()
                
                Button {
                    HapticManager.impact(.light)
                    viewModel.showingRFCExport = true
                } label: {
                    Label("View Raw RFC 1035 Output", systemImage: "terminal")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
        }
    }
    
    // MARK: - 3. Benchmark Results
    @ViewBuilder
    private var benchmarkResultsView: some View {
        if viewModel.isBenchmarkLoading {
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
                Text("Benchmarking Global Resolvers...")
                    .font(.headline)
                Divider()
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        Circle().frame(width: CloudnsSize.iconLarge, height: CloudnsSize.iconLarge)
                        Text("Cloudflare 1.1.1.1")
                        Spacer()
                        Text("12.4 ms")
                    }
                }
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
            .skeletonLoading(true)
        } else if let bench = viewModel.benchmarkResult {
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
                Text("Resolver Latency & Accuracy Benchmark")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Divider()
                
                VStack(spacing: CloudnsSpacing.mdSmall) {
                    ForEach(bench.items) { item in
                        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                            HStack {
                                Image(systemName: item.icon)
                                    .foregroundStyle(item.color)
                                    .frame(width: CloudnsSize.iconLarge, height: CloudnsSize.iconLarge)
                                
                                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
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
                                    .padding(.leading, CloudnsSpacing.xl)
                            }
                        }
                    }
                }
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
        }
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Query Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Actions
    private func startQuery() {
        guard !viewModel.domainInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        historyManager.recordQuery(viewModel.domainInput, for: .dnsDig)
        Task {
            if queryMode == 0 {
                await viewModel.queryDNS()
            } else {
                await viewModel.runDNSBenchmark()
            }
        }
    }
}
