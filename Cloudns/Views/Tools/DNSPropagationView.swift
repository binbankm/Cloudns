import SwiftUI

// MARK: - DNSPropagationView
// Apple HIG Compliant Worldwide DNS Propagation Probe

struct DNSPropagationView: View {
    @StateObject private var viewModel = DNSPropagationViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Target Domain Input
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "globe.americas.fill")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    
                    TextField("example.com", text: $viewModel.propagationDomain)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(.body.monospacedDigit())
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.queryPropagation() }
                        }
                    
                    if !viewModel.propagationDomain.isEmpty {
                        Button {
                            viewModel.propagationDomain = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear Domain")
                    }
                }
                
                HStack {
                    Text("Record Type")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Record Type", selection: $viewModel.propagationType) {
                        ForEach(["A", "AAAA", "CNAME", "MX", "TXT", "NS"], id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .foregroundStyle(.secondary)
                    TextField("Expected Value (Optional)", text: $viewModel.expectedIP)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospacedDigit())
                }
                
                Button {
                    isFieldFocused = false
                    HapticManager.impact(.light)
                    Task { await viewModel.queryPropagation() }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isPropagationLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text(viewModel.isPropagationLoading ? "Probing Global Edge…" : "Probe Worldwide DNS Propagation")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.propagationDomain.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isPropagationLoading)
            } header: {
                Text("Propagation Target")
            } footer: {
                Text("Simultaneously probes DNS answers across 8 Anycast edge resolvers across North America, Europe, Asia, Australia & South America.")
            }
            
            if viewModel.isPropagationLoading {
                Section("Querying 8 Global Edge Nodes…") {
                    HStack {
                        Spacer()
                        ProgressView("Probing Anycast Edge Resolvers…")
                            .padding(.vertical, 8)
                        Spacer()
                    }
                }
            } else if let result = viewModel.propagationResult {
                // 1. Worldwide Propagation Score Card
                Section("Global Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Propagation Score")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                (Text(verbatim: "\(result.propagationPercent)% ") + Text("Synchronized"))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(result.propagationPercent >= 100 ? Color.green : (result.propagationPercent >= 50 ? Color.orange : Color.red))
                            }
                            
                            Spacer()
                            
                            let isSuccess = result.propagationPercent >= 100
                            Text("\(result.matchedCount)/\(result.nodes.count) Nodes")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(isSuccess ? Color.green : Color.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill((isSuccess ? Color.green : Color.orange).opacity(0.12)))
                        }
                        
                        ProgressView(value: Double(result.propagationPercent) / 100.0)
                            .tint(result.propagationPercent >= 100 ? Color.green : Color.orange)
                    }
                    .padding(.vertical, 2)
                }
                
                // 2. Regional Nodes Breakdown
                Section("Regional Edge Resolvers (\(result.nodes.count))") {
                    ForEach(result.nodes) { node in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(node.countryFlag)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(node.regionName)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(node.locationCity) • \(node.provider)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                nodeStatusBadge(node.status)
                            }
                            
                            if !node.resolvedIPs.isEmpty {
                                Text(node.resolvedIPs.joined(separator: ", "))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.primary)
                                    .padding(.leading, 32)
                            }
                            
                            if let lat = node.latencyMs {
                                Text("Latency: \(lat.formatted(.number.precision(.fractionLength(1)))) ms")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 32)
                            }
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            Button {
                                copyToClipboard(node.resolvedIPs.joined(separator: ", "), toast: "IPs Copied")
                            } label: {
                                Label("Copy Resolved IPs", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
            } else if let error = viewModel.propagationError {
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
        .navigationTitle("DNS Propagation")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func nodeStatusBadge(_ status: DNSPropagationNode.NodeStatus) -> some View {
        switch status {
        case .resolved:
            Text("Matched")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.green.opacity(0.12)))
        case .mismatch:
            Text("Mismatch")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange.opacity(0.12)))
        case .failed:
            Text("Failed")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.red)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.red.opacity(0.12)))
        case .pending:
            Text("Pending")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange.opacity(0.12)))
        }
    }
}
