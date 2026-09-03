import SwiftUI

// MARK: - CIDRCalculatorView
// Apple HIG Compliant IP Subnet & CIDR Calculator

struct CIDRCalculatorView: View {
    @StateObject private var viewModel = CIDRCalculatorViewModel()
    @FocusState private var isFieldFocused: Bool
    
    private let presetCIDRs = [
        "192.168.1.0/24",
        "10.0.0.0/8",
        "172.16.0.0/12",
        "104.16.0.0/12",
        "172.64.0.0/13",
        "1.1.1.0/24",
        "2606:4700::/32"
    ]
    
    var body: some View {
        List {
            // 1. Input & Presets Section
            Section(header: Text("CIDR Notation / IP Subnet"), footer: Text("Calculates usable IP host addresses, network broadcast bounds, netmasks & binary bitmasks.")) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "number.square.fill")
                        .font(HIGTypography.body)
                        .foregroundStyle(Color.higAccent)
                        .accessibilityHidden(true)
                    
                    TextField("192.168.1.0/24 or 2606:4700::/32", text: $viewModel.cidrInput)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(HIGTypography.body.monospacedDigit())
                        .onChange(of: viewModel.cidrInput) { _ in
                            viewModel.calculateSubnet()
                        }
                    
                    if !viewModel.cidrInput.isEmpty {
                        Button {
                            viewModel.cidrInput = ""
                            viewModel.calculateSubnet()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .higTouchTarget(44)
                        .accessibilityLabel("Clear Input")
                    }
                }
                
                // Quick Presets
                ScrollView(.horizontal) {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        ForEach(presetCIDRs, id: \.self) { preset in
                            Button {
                                viewModel.cidrInput = preset
                                viewModel.calculateSubnet()
                                HIGFeedback.selection()
                            } label: {
                                Text(preset)
                                    .font(HIGTypography.caption.weight(.medium).monospacedDigit())
                                    .padding(.horizontal, HIGTokens.Spacing.sm + 2)
                                    .padding(.vertical, HIGTokens.Spacing.xxs + 3)
                                    .background(viewModel.cidrInput == preset ? Color.higAccent : Color.higAccent.opacity(0.12))
                                    .foregroundStyle(viewModel.cidrInput == preset ? .white : Color.higAccent)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.higPressable)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            
            if let result = viewModel.subnetResult {
                // 2. Subnet Range Hero Section
                Section(header: Text("Subnet & Host Range")) {
                    HStack {
                        Text("Usable Hosts Count")
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HIGBadge(.active("\(result.totalUsableHosts) Hosts"), isCompact: true)
                    }
                    
                    calcRow(label: "Network Address", value: result.networkAddress)
                    calcRow(label: "Broadcast Address", value: result.broadcastAddress)
                    calcRow(label: "Usable Host Range", value: result.usableHostRange)
                }
                
                // 3. Properties Section
                Section(header: Text("Masks & Network Properties")) {
                    calcRow(label: "Subnet Netmask", value: result.netmask)
                    calcRow(label: "Wildcard Mask", value: result.wildcardMask)
                    calcRow(label: "Prefix Length", value: "/\(result.prefixLength)")
                    calcRow(label: "IP Class / Type", value: result.ipClass)
                }
                
                // 4. Binary Bitmask Section
                Section(header: Text("Binary Bitmask")) {
                    HStack {
                        Text(result.binaryMask)
                            .font(HIGTypography.caption.monospaced())
                            .foregroundStyle(Color.higAccent)
                            .textSelection(.enabled)
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = result.binaryMask
                            ToastManager.shared.showCopied("Binary Mask Copied")
                            HIGFeedback.copied()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.higPressable)
                        .higTouchTarget(44)
                    }
                }
            } else if let error = viewModel.subnetError {
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
        .navigationTitle("CIDR Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .task {
            viewModel.calculateSubnet()
        }
    }
    
    @ViewBuilder
    private func calcRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(verbatim: value)
                .font(HIGTypography.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
            
            Button {
                UIPasteboard.general.string = value
                ToastManager.shared.showCopied("\(value) Copied")
                HIGFeedback.copied()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.higPressable)
            .higTouchTarget(44)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = value
                ToastManager.shared.showCopied("Value Copied")
                HIGFeedback.copied()
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
        }
    }
}
