import SwiftUI

struct EdgeLatencyTestView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Target Host Input
            Section(header: Text("Target Edge Host")) {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundStyle(.purple)
                        .accessibilityHidden(true)
                    
                    TextField("https://example.com", text: $viewModel.latencyHostInput)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.go)
                        .onSubmit {
                            Task { await viewModel.testLatency() }
                        }
                    
                    if !viewModel.latencyHostInput.isEmpty {
                        Button {
                            viewModel.latencyHostInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Stepper("Test Rounds: \(viewModel.latencyRounds)", value: $viewModel.latencyRounds, in: 3...10)
                
                Button {
                    isFieldFocused = false
                    HapticManager.impact(.light)
                    Task { await viewModel.testLatency() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLatencyLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "bolt.horizontal.fill")
                        }
                        Text("Start Multi-Round Latency Test")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.purple)
                        Spacer()
                    }
                }
                .disabled(viewModel.latencyHostInput.isEmpty || viewModel.isLatencyLoading)
            }
            
            if viewModel.isLatencyLoading {
                Section(header: Text("Testing Edge Latency Over Consecutive Requests...")) {
                    HStack {
                        Text("Round 1...").redacted(reason: .placeholder)
                        Spacer()
                        Text("42.5 ms").redacted(reason: .placeholder)
                    }
                    .skeletonLoading(true)
                }
            } else if let result = viewModel.latencyResult {
                // 1. Latency & Jitter Metrics Card
                Section(header: Text("Latency & Jitter Summary")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
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
                            Text(String(format: "%.0f%%", result.packetLossPercent))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(result.packetLossPercent == 0 ? .green : .red)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 2. Protocol & Server Info
                Section(header: Text("Edge Protocol & Server")) {
                    HStack {
                        Text("Negotiated Protocol")
                            .foregroundStyle(.secondary)
                        Spacer()
                        CloudnsBadge(.active(result.httpProtocol), isCompact: true)
                    }
                    
                    HStack {
                        Text("Edge Server")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if result.isCloudflareEdge {
                            CloudnsBadge(.proxied("Cloudflare Edge"), isCompact: true)
                        } else {
                            Text(result.serverHeader)
                                .font(.subheadline)
                        }
                    }
                }
                
                // 3. Consecutive Ping Rounds
                Section(header: Text("Test Rounds Breakdown (\(result.pings.count))")) {
                    ForEach(result.pings) { ping in
                        HStack {
                            Text("Round #\(ping.id)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if ping.isSuccess {
                                Text("\(ping.httpStatus) OK")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                
                                Text(String(format: "%.1f ms", ping.latencyMs))
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(ping.latencyMs < 50 ? .green : (ping.latencyMs < 100 ? .orange : .red))
                            } else {
                                Text("Failed / Timeout")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            } else if let error = viewModel.latencyError {
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
        .navigationTitle("Edge Latency & Jitter")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func metricBox(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
        }
    }
}
