import SwiftUI

// MARK: - EdgeLatencyTestView
// Apple HIG Compliant Edge Latency & Jitter Benchmark

struct EdgeLatencyTestView: View {
    @StateObject private var viewModel = EdgeLatencyViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // 1. Input & Rounds Section
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "speedometer")
                        .foregroundStyle(.tint)
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
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear Input")
                    }
                }
                
                Stepper("Test Rounds: \(viewModel.latencyRounds)", value: $viewModel.latencyRounds, in: 3...10)
                    .font(.subheadline)
                    .onChange(of: viewModel.latencyRounds) { _ in
                        HapticManager.selection()
                    }
                
                Button {
                    performTest()
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isLatencyLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "bolt.horizontal.fill")
                        }
                        Text(viewModel.isLatencyLoading ? LocalizedStringKey("Testing Consecutive Pings…") : LocalizedStringKey("Start Latency & Jitter Benchmark"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.latencyHostInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLatencyLoading)
            } header: {
                Text("Target Host")
            } footer: {
                Text("Sends consecutive HTTP/HTTPS HEAD probes to measure edge latency, round-trip time jitter & packet consistency.")
            }
            
            if viewModel.isLatencyLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Testing Edge Latency…")
                            .padding(.vertical, 8)
                        Spacer()
                    }
                }
            } else if let result = viewModel.latencyResult {
                // 2. Metrics Hero Section
                Section("Latency & Jitter Summary") {
                    metricsRows(result: result)
                }
                
                // 3. Protocol Info Section
                Section("Edge Protocol & Server") {
                    protocolRows(result: result)
                }
                
                // 4. Round Breakdown Section
                Section("Round-by-Round Breakdown (\(result.pings.count))") {
                    roundsRows(result: result)
                }
            } else if let error = viewModel.latencyError {
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
            if !viewModel.latencyHostInput.isEmpty {
                await viewModel.testLatency()
            }
        }
        .navigationTitle("Edge Latency Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performTest() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.testLatency() }
    }
    
    // MARK: - 2. Metrics Rows
    @ViewBuilder
    private func metricsRows(result: EdgeLatencyResult) -> some View {
        HStack {
            Text("Average Latency")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(result.avgMs.formatted(.number.precision(.fractionLength(1)))) ms")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(.green)
        }
        
        HStack {
            Text("Min / Max Latency")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(result.minMs.formatted(.number.precision(.fractionLength(1)))) ms / \(result.maxMs.formatted(.number.precision(.fractionLength(1)))) ms")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
        
        HStack {
            Text("Jitter")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("±\(result.jitterMs.formatted(.number.precision(.fractionLength(1)))) ms")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.orange)
        }
        
        HStack {
            Text("Packet Loss")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text((result.packetLossPercent / 100.0), format: .percent.precision(.fractionLength(0)))
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(result.packetLossPercent == 0 ? Color.green : Color.red)
        }
    }
    
    // MARK: - 3. Protocol Rows
    @ViewBuilder
    private func protocolRows(result: EdgeLatencyResult) -> some View {
        HStack {
            Text("Protocol")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(result.httpProtocol)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.green.opacity(0.12)))
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
    
    // MARK: - 4. Rounds Rows
    @ViewBuilder
    private func roundsRows(result: EdgeLatencyResult) -> some View {
        ForEach(result.pings) { ping in
            HStack {
                Text("Round \(ping.id)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if ping.isSuccess {
                    Text("\(ping.latencyMs.formatted(.number.precision(.fractionLength(1)))) ms")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(ping.latencyMs < 50 ? Color.green : (ping.latencyMs < 120 ? Color.orange : Color.red))
                } else {
                    Text("Failed")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
