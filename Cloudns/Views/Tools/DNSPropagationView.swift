import SwiftUI

// MARK: - DNSPropagationView
// Apple HIG Compliant Worldwide DNS Propagation Probe

struct DNSPropagationView: View {
    @StateObject private var viewModel = DNSPropagationViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Target Domain Input
            Section(header: Text("Propagation Target"), footer: Text("Simultaneously probes DNS answers across 8 Anycast edge resolvers across North America, Europe, Asia, Australia & South America.")) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "globe.americas.fill")
                        .font(HIGTypography.body)
                        .foregroundStyle(Color.higAccent)
                        .accessibilityHidden(true)
                    
                    TextField("example.com", text: $viewModel.propagationDomain)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(HIGTypography.body.monospacedDigit())
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
                        .buttonStyle(.plain)
                        .higTouchTarget(44)
                        .accessibilityLabel("Clear Domain")
                    }
                }
                
                HStack {
                    Text("Record Type")
                        .font(HIGTypography.subheadline)
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
                
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "target")
                        .font(HIGTypography.body)
                        .foregroundStyle(.secondary)
                    TextField("Expected Value (Optional)", text: $viewModel.expectedIP)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(HIGTypography.body.monospacedDigit())
                }
                
                Button {
                    isFieldFocused = false
                    HIGFeedback.impact(.light)
                    Task { await viewModel.queryPropagation() }
                } label: {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        if viewModel.isPropagationLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text(viewModel.isPropagationLoading ? "Probing Global Edge…" : "Probe Worldwide DNS Propagation")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.propagationDomain.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isPropagationLoading ? Color(.tertiaryLabel) : Color.higAccent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.higPressable)
                .disabled(viewModel.propagationDomain.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isPropagationLoading)
            }
            
            if viewModel.isPropagationLoading {
                Section(header: Text("Querying 8 Global Edge Nodes…")) {
                    HIGContentState(.loading(message: "Probing Anycast Edge Resolvers…"))
                        .padding(.vertical, HIGTokens.Spacing.sm)
                }
            } else if let result = viewModel.propagationResult {
                // 1. Worldwide Propagation Score Card
                Section(header: Text("Global Status")) {
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                Text("Propagation Score")
                                    .font(HIGTypography.caption)
                                    .foregroundStyle(.secondary)
                                
                                (Text(verbatim: "\(result.propagationPercent)% ") + Text("Synchronized"))
                                    .font(HIGTypography.title3.weight(.bold))
                                    .foregroundStyle(result.propagationPercent >= 100 ? HIGColors.success : (result.propagationPercent >= 50 ? HIGColors.warning : HIGColors.error))
                            }
                            
                            Spacer()
                            
                            HIGBadge(result.propagationPercent >= 100 ? .active("\(result.matchedCount)/\(result.nodes.count) Nodes") : .warning("\(result.matchedCount)/\(result.nodes.count) Nodes"), isCompact: false)
                        }
                        
                        ProgressView(value: Double(result.propagationPercent) / 100.0)
                            .tint(result.propagationPercent >= 100 ? HIGColors.success : HIGColors.warning)
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                }
                
                // 2. Regional Nodes Breakdown
                Section(header: Text("Regional Edge Resolvers (\(result.nodes.count))")) {
                    ForEach(result.nodes) { node in
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                            HStack {
                                Text(node.countryFlag)
                                    .font(HIGTypography.title3)
                                
                                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                    Text(node.regionName)
                                        .font(HIGTypography.subheadline.weight(.semibold))
                                    Text("\(node.locationCity) • \(node.provider)")
                                        .font(HIGTypography.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                nodeStatusBadge(node.status)
                            }
                            
                            if !node.resolvedIPs.isEmpty {
                                Text(node.resolvedIPs.joined(separator: ", "))
                                    .font(HIGTypography.caption.monospaced())
                                    .foregroundStyle(.primary)
                                    .padding(.leading, 32)
                            }
                            
                            if let lat = node.latencyMs {
                                Text("Latency: \(lat.formatted(.number.precision(.fractionLength(1)))) ms")
                                    .font(HIGTypography.caption2.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 32)
                            }
                        }
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = node.resolvedIPs.joined(separator: ", ")
                                ToastManager.shared.showCopied("IPs Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Resolved IPs", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
            } else if let error = viewModel.propagationError {
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
        .navigationTitle("DNS Propagation")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func nodeStatusBadge(_ status: DNSPropagationNode.NodeStatus) -> some View {
        switch status {
        case .resolved:
            HIGBadge(.active("Matched"), isCompact: true)
        case .mismatch:
            HIGBadge(.warning("Mismatch"), isCompact: true)
        case .failed:
            HIGBadge(.custom(color: HIGColors.error, text: "Failed"), isCompact: true)
        case .pending:
            HIGBadge(.proxied("Pending"), isCompact: true)
        }
    }
}
