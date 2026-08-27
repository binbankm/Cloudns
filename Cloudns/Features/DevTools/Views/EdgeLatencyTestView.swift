import SwiftUI

struct EdgeLatencyTestView: View {
    // MARK: - Properties
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack {
            CloudnsColor.groupedBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: CloudnsSpacing.md) {
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
                .padding(.horizontal, CloudnsSpacing.md)
                .padding(.vertical, CloudnsSpacing.mdSmall)
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
        VStack(spacing: CloudnsSpacing.mdMedium) {
            HStack(spacing: CloudnsSpacing.smMd) {
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
            .padding(CloudnsSpacing.mdSmall)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            
            Stepper("Test Rounds: \(viewModel.latencyRounds)", value: $viewModel.latencyRounds, in: 3...10)
                .font(.subheadline)
            
            CloudnsButton(
                viewModel.isLatencyLoading ? "Testing Consecutive Pings..." : "Start Latency & Jitter Benchmark",
                icon: "bolt.horizontal.fill",
                style: .primary(color: .purple),
                size: .regular,
                isFullWidth: true,
                isLoading: viewModel.isLatencyLoading,
                disabled: viewModel.latencyHostInput.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                performTest()
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Actions
    private func performTest() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.testLatency() }
    }
    
    // MARK: - 2. Metrics Card
    @ViewBuilder
    private func metricsCard(result: EdgeLatencyResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdMedium) {
            Text("Latency & Jitter Summary")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            HStack(spacing: CloudnsSpacing.mdSmall) {
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
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    @ViewBuilder
    private func metricBox(title: LocalizedStringKey, value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: CloudnsSpacing.xs) {
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
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Edge Protocol & Server")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.smMd) {
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
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 4. Rounds Card
    @ViewBuilder
    private func roundsCard(result: EdgeLatencyResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Round-by-Round Breakdown (\(result.pings.count))")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.sm) {
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
                    .padding(.vertical, CloudnsSpacing.xxs)
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Test Failed")
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
    
    // MARK: - Skeleton View
    private var loadingSkeletonView: some View {
        VStack(spacing: CloudnsSpacing.md) {
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
                Text("Latency & Jitter Summary")
                    .font(.headline)
                Divider()
                HStack {
                    Text("24.5 ms").font(.headline.weight(.bold))
                    Spacer()
                    Text("±2.1 ms")
                }
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
            .skeletonLoading(true)
        }
    }
}
