import SwiftUI

struct DNSPropagationView: View {
    @StateObject private var viewModel = DevToolsViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Target Domain Input
            Section(header: Text("Propagation Target")) {
                HStack {
                    Image(systemName: "globe.americas.fill")
                        .foregroundStyle(.indigo)
                        .accessibilityHidden(true)
                    
                    TextField("example.com", text: $viewModel.propagationDomain)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
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
                        }
                    }
                }
                
                HStack {
                    Text("Record Type")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Record Type", selection: $viewModel.propagationType) {
                        ForEach(["A", "AAAA", "CNAME", "MX", "TXT", "NS"], id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(.secondary)
                    TextField("Expected Value (Optional)", text: $viewModel.expectedIP)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Button {
                    isFieldFocused = false
                    HIGFeedback.impact(.light)
                    Task { await viewModel.queryPropagation() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isPropagationLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text("Probe Worldwide DNS Propagation")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.indigo)
                        Spacer()
                    }
                }
                .disabled(viewModel.propagationDomain.isEmpty || viewModel.isPropagationLoading)
            }
            
            if viewModel.isPropagationLoading {
                Section(header: Text("Querying 8 Global Edge Nodes...")) {
                    ForEach(0..<8, id: \.self) { _ in
                        HStack {
                            Text("🇺🇸 North America (East)")
                            Spacer()
                            Text("Matched")
                        }
                    }
                }
                .redacted(reason: .placeholder)
            } else if let result = viewModel.propagationResult {
                // 1. Worldwide Propagation Score Card
                Section(header: Text("Global Status")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Propagation Score")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                (Text(verbatim: "\(result.propagationPercent)% ") + Text("Synchronized"))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(result.propagationPercent >= 100 ? .green : (result.propagationPercent >= 50 ? .orange : .red))
                            }
                            
                            Spacer()
                            
                            HIGBadge(result.propagationPercent >= 100 ? .active("\(result.matchedCount)/\(result.nodes.count) Nodes") : .warning("\(result.matchedCount)/\(result.nodes.count) Nodes"), isCompact: false)
                        }
                        
                        ProgressView(value: Double(result.propagationPercent) / 100.0)
                            .tint(result.propagationPercent >= 100 ? .green : .orange)
                    }
                    .padding(.vertical, 4)
                }
                
                // 2. Regional Nodes Breakdown
                Section(header: Text("Regional Edge Resolvers (\(result.nodes.count))")) {
                    ForEach(result.nodes) { node in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(node.countryFlag)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 1) {
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
                                Text(String(format: "Latency: %.1f ms", lat)).font(.caption.monospacedDigit())
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 32)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if let error = viewModel.propagationError {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Global DNS Propagation")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func nodeStatusBadge(_ status: DNSPropagationNode.NodeStatus) -> some View {
        switch status {
        case .resolved:
            HIGBadge(.active("Resolved"), isCompact: true)
        case .mismatch:
            HIGBadge(.warning("Divergent"), isCompact: true)
        case .failed:
            HIGBadge(.error("Failed"), isCompact: true)
        case .pending:
            HIGBadge(.dnsOnly("Probing"), isCompact: true)
        }
    }
}
