import SwiftUI

// MARK: - EdgeLatencyTestView
// Apple HIG Compliant Edge Latency & Jitter Benchmark

struct EdgeLatencyTestView: View {
    @StateObject private var viewModel = EdgeLatencyViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // 1. Input & Rounds Section
            Section(header: Text("Target Host"), footer: Text("Sends consecutive HTTP/HTTPS HEAD probes to measure edge latency, round-trip time jitter & packet consistency.")) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "speedometer")
                        .font(HIGTypography.body)
                        .foregroundStyle(Color.higAccent)
                        .accessibilityHidden(true)
                    
                    TextField("https://example.com", text: $viewModel.latencyHostInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(HIGTypography.body.monospacedDigit())
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
                        .buttonStyle(.plain)
                        .higTouchTarget(44)
                        .accessibilityLabel("Clear Input")
                    }
                }
                
                Stepper("Test Rounds: \(viewModel.latencyRounds)", value: $viewModel.latencyRounds, in: 3...10)
                    .font(HIGTypography.subheadline)
                    .onChange(of: viewModel.latencyRounds) { _ in
                        HIGFeedback.selection()
                    }
                
                Button {
                    performTest()
                } label: {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        if viewModel.isLatencyLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "bolt.horizontal.fill")
                        }
                        Text(viewModel.isLatencyLoading ? "Testing Consecutive Pings…" : "Start Latency & Jitter Benchmark")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.latencyHostInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLatencyLoading ? Color(.tertiaryLabel) : Color.higAccent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.higPressable)
                .disabled(viewModel.latencyHostInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLatencyLoading)
            }
            
            if viewModel.isLatencyLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Testing Edge Latency…")
                            .font(HIGTypography.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, HIGTokens.Spacing.sm)
                }
            } else if let result = viewModel.latencyResult {
                // 2. Metrics Hero Section
                Section(header: Text("Latency & Jitter Summary")) {
                    metricsRows(result: result)
                }
                
                // 3. Protocol Info Section
                Section(header: Text("Edge Protocol & Server")) {
                    protocolRows(result: result)
                }
                
                // 4. Round Breakdown Section
                Section(header: Text("Round-by-Round Breakdown (\(result.pings.count))")) {
                    roundsRows(result: result)
                }
            } else if let error = viewModel.latencyError {
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
            if !viewModel.latencyHostInput.isEmpty {
                await viewModel.testLatency()
            }
        }
        .navigationTitle("Edge Latency Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performTest() {
        isFieldFocused = false
        HIGFeedback.impact(.light)
        Task { await viewModel.testLatency() }
    }
    
    // MARK: - 2. Metrics Rows
    @ViewBuilder
    private func metricsRows(result: EdgeLatencyResult) -> some View {
        HStack {
            Text("Average Latency")
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(result.avgMs.formatted(.number.precision(.fractionLength(1)))) ms")
                .font(HIGTypography.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(HIGColors.success)
        }
        
        HStack {
            Text("Min / Max Latency")
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(result.minMs.formatted(.number.precision(.fractionLength(1)))) ms / \(result.maxMs.formatted(.number.precision(.fractionLength(1)))) ms")
                .font(HIGTypography.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
        
        HStack {
            Text("Jitter")
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("±\(result.jitterMs.formatted(.number.precision(.fractionLength(1)))) ms")
                .font(HIGTypography.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(HIGColors.warning)
        }
        
        HStack {
            Text("Packet Loss")
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text((result.packetLossPercent / 100.0), format: .percent.precision(.fractionLength(0)))
                .font(HIGTypography.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(result.packetLossPercent == 0 ? HIGColors.success : HIGColors.error)
        }
    }
    
    // MARK: - 3. Protocol Rows
    @ViewBuilder
    private func protocolRows(result: EdgeLatencyResult) -> some View {
        HStack {
            Text("Protocol")
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HIGBadge(.active(result.httpProtocol), isCompact: true)
        }
        
        if !result.serverHeader.isEmpty {
            HStack {
                Text("Server Banner")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(result.serverHeader)
                    .font(HIGTypography.subheadline.monospaced())
                    .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: - 4. Rounds Rows
    @ViewBuilder
    private func roundsRows(result: EdgeLatencyResult) -> some View {
        ForEach(result.pings) { ping in
            HStack {
                Text("Round \(ping.id)")
                    .font(HIGTypography.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if ping.isSuccess {
                    Text("\(ping.latencyMs.formatted(.number.precision(.fractionLength(1)))) ms")
                        .font(HIGTypography.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(ping.latencyMs < 50 ? HIGColors.success : (ping.latencyMs < 120 ? HIGColors.warning : HIGColors.error))
                } else {
                    Text("Failed")
                        .font(HIGTypography.subheadline.weight(.medium))
                        .foregroundStyle(HIGColors.error)
                }
            }
        }
    }
}
