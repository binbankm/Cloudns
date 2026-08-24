import SwiftUI

struct EdgeLatencyTestView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Input & Rounds Card
                    inputCard
                    
                    if viewModel.isLatencyLoading {
                        loadingSkeletonView
                    } else if let result = viewModel.latencyResult {
                        // 2. Metrics Hero Card
                        metricsCard(result: result)
                        
                        // 3. Protocol Info Card
                        protocolCard(result: result)
                        
                        // 4. Round Breakdown Card
                        roundsCard(result: result)
                    } else if let error = viewModel.latencyError {
                        errorCard(message: error)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.latencyHostInput.isEmpty {
                    HapticManager.impact(.light)
                    await viewModel.testLatency()
                }
            }
        }
        .navigationTitle("Edge Latency Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "speedometer")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .accessibilityHidden(true)
                
                TextField("https://example.com", text: $viewModel.latencyHostInput)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)
                    .font(.body.monospacedDigit())
                    .submitLabel(.go)
                    .onSubmit {
                        performTest()
                    }
                
                if !viewModel.latencyHostInput.isEmpty {
                    Button {
                        viewModel.latencyHostInput = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear input")
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Stepper("Test Rounds: \(viewModel.latencyRounds)", value: $viewModel.latencyRounds, in: 3...10)
                .font(.subheadline)
            
            Button {
                performTest()
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isLatencyLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "bolt.horizontal.fill")
                    }
                    Text(viewModel.isLatencyLoading ? "Testing Consecutive Pings..." : "Start Latency & Jitter Benchmark")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.regular)
            .disabled(viewModel.latencyHostInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLatencyLoading)
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    private func performTest() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.testLatency() }
    }
    
    // MARK: - 2. Metrics Card
    @ViewBuilder
    private func metricsCard(result: EdgeLatencyResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Latency & Jitter Summary")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            HStack(spacing: 12) {
                metricBox(title: "Avg Latency", value: String(format: "%.1f ms", result.avgMs), color: .green)
                Spacer()
                metricBox(title: "Min / Max", value: String(format: "%.0f / %.0f", result.minMs, result.maxMs), color: .blue)
                Spacer()
                metricBox(title: "Jitter", value: String(format: "±%.1f ms", result.jitterMs), color: .orange)
            }
            
            Divider()
            
            HStack {
                Text("Packet Loss")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: String(format: "%.0f%%", result.packetLossPercent))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(result.packetLossPercent == 0 ? .green : .red)
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    @ViewBuilder
    private func metricBox(title: LocalizedStringKey, value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(minWidth: 80)
    }
    
    // MARK: - 3. Protocol Card
    @ViewBuilder
    private func protocolCard(result: EdgeLatencyResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edge Protocol & Server")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 10) {
                HStack {
                    Text("Protocol")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    CloudnsBadge(.active(result.httpProtocol), isCompact: true)
                }
                
                if !result.serverHeader.isEmpty {
                    HStack {
                        Text("Server Banner")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(result.serverHeader)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 4. Rounds Card
    @ViewBuilder
    private func roundsCard(result: EdgeLatencyResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Round-by-Round Breakdown (\(result.pings.count))")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 8) {
                ForEach(result.pings) { ping in
                    HStack {
                        Text("Round \(ping.id)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if ping.isSuccess {
                            Text(String(format: "%.1f ms", ping.latencyMs))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(ping.latencyMs < 50 ? .green : (ping.latencyMs < 120 ? .orange : .red))
                        } else {
                            Text("Failed")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Test Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - Skeleton View
    private var loadingSkeletonView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Latency & Jitter Summary")
                    .font(.headline)
                Divider()
                HStack {
                    Text("24.5 ms").font(.headline.weight(.bold))
                    Spacer()
                    Text("±2.1 ms")
                }
            }
            .padding(16)
            .cloudnsCard(style: .frosted, cornerRadius: 16)
            .skeletonLoading(true)
        }
    }
}
