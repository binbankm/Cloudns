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
            Section(header: Text("Query Configuration"), footer: Text("Queries 1.1.1.1 Anycast edge resolver with optional DNSSEC verification or benchmarks worldwide public resolvers.")) {
                Picker("Query Mode", selection: $queryMode) {
                    Text("1.1.1.1 Edge Query").tag(0)
                    Text("Multi-Resolver Benchmark").tag(1)
                }
                .pickerStyle(.segmented)
                .onChange(of: queryMode) { _ in
                    HIGFeedback.selection()
                }
                
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "globe")
                        .font(HIGTypography.body)
                        .foregroundStyle(Color.higAccent)
                        .accessibilityHidden(true)
                    
                    TextField("e.g. example.com", text: $viewModel.domainInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(HIGTypography.body.monospacedDigit())
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
                        .higTouchTarget(44)
                        .accessibilityLabel("Clear Domain")
                    }
                }
                
                if queryMode == 0 {
                    HStack {
                        Text("Record Type")
                            .font(HIGTypography.subheadline)
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
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        if viewModel.isDnsLoading || viewModel.isBenchmarkLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(viewModel.isDnsLoading || viewModel.isBenchmarkLoading ? "Querying Resolvers…" : (queryMode == 0 ? "Query 1.1.1.1 Resolver" : "Benchmark 5 Resolvers"))
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isDnsLoading || viewModel.isBenchmarkLoading ? Color(.tertiaryLabel) : Color.higAccent)
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
                                .font(HIGTypography.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, HIGTokens.Spacing.sm)
                    }
                } else if let result = viewModel.dnsResult {
                    Section(header: Text("Resolved Answers (\(result.answers.count))")) {
                        HStack {
                            Text("Resolver Engine")
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if result.isDNSSECValidated {
                                HIGBadge(.custom(color: HIGColors.success, text: "DNSSEC Validated"), isCompact: true)
                            }
                            HIGBadge(.custom(color: Color.higAccent, text: "\(result.latencyMs.formatted(.number.precision(.fractionLength(1)))) ms"), isCompact: true)
                        }
                        
                        if result.answers.isEmpty {
                            Text("No DNS records found for this query.")
                                .font(HIGTypography.subheadline)
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
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(Color.higAccent)
                        }
                    }
                }
            } else {
                if viewModel.isBenchmarkLoading {
                    Section(header: Text("Benchmarking Public Resolvers…")) {
                        HStack(spacing: HIGTokens.Spacing.sm) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Probing Cloudflare, Google, Quad9, OpenDNS…")
                                .font(HIGTypography.subheadline)
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
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HIGColors.error)
                        Text(verbatim: error)
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(HIGColors.error)
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
                                .font(HIGTypography.caption.monospaced())
                                .padding(HIGTokens.Spacing.lg)
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
                                    ToastManager.shared.showCopied("RFC Output Copied")
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
        HStack(spacing: HIGTokens.Spacing.md) {
            if let rank = rank {
                Text("\(rank)")
                    .font(HIGTypography.body.weight(.bold).monospacedDigit())
                    .foregroundStyle(rank == 1 ? Color.yellow : Color.secondary)
                    .frame(width: 20)
            }
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(verbatim: item.resolverName)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(verbatim: item.resolverIP)
                    .font(HIGTypography.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if item.status == "OK", let lat = item.latencyMs {
                HIGBadge(.custom(color: rank == 1 ? HIGColors.success : Color.higAccent, text: "\(lat.formatted(.number.precision(.fractionLength(1)))) ms"), isCompact: true)
            } else {
                HIGBadge(.custom(color: HIGColors.error, text: "TIMEOUT"), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
        .contextMenu {
            Button {
                UIPasteboard.general.string = item.resolverIP
                ToastManager.shared.showCopied("IP Copied")
                HIGFeedback.copied()
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
        HStack(alignment: .center, spacing: HIGTokens.Spacing.sm) {
            HIGBadge(.custom(color: .indigo, text: item.typeName), isCompact: true)
            
            Text(verbatim: item.data)
                .font(HIGTypography.body.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Text("TTL \(item.ttl)s")
                .font(HIGTypography.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            
            Button {
                HIGFeedback.copied()
                UIPasteboard.general.string = item.data
                ToastManager.shared.showCopied("Record Data Copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.higPressable)
            .higTouchTarget(44)
            .accessibilityLabel("Copy \(item.typeName) record: \(item.data)")
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
        .contextMenu {
            Button {
                UIPasteboard.general.string = item.data
                ToastManager.shared.showCopied("Data Copied")
                HIGFeedback.copied()
            } label: {
                Label("Copy Record Data", systemImage: "doc.on.doc")
            }
        }
    }
}
