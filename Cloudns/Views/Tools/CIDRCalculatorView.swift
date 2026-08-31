import SwiftUI

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
                HStack(spacing: 10) {
                    Image(systemName: "number.square.fill")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("192.168.1.0/24 or 2606:4700::/32", text: $viewModel.cidrInput)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(.body.monospacedDigit())
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
                        .accessibilityLabel("Clear input")
                    }
                }
                
                // Quick Presets
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(presetCIDRs, id: \.self) { preset in
                            Button {
                                viewModel.cidrInput = preset
                                viewModel.calculateSubnet()
                                HIGFeedback.selection()
                            } label: {
                                Text(preset)
                                    .font(.caption.weight(.medium).monospacedDigit())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(viewModel.cidrInput == preset ? Color.blue : Color.blue.opacity(0.12))
                                    .foregroundStyle(viewModel.cidrInput == preset ? .white : .blue)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
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
                            .font(.subheadline)
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
                            .font(.caption.monospaced())
                            .foregroundStyle(.blue)
                            .textSelection(.enabled)
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = result.binaryMask
                            ToastManager.shared.showCopied()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .higTouchTarget()
                    }
                }
            } else if let error = viewModel.subnetError {
                Section(header: Text("Error")) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(verbatim: error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Subnet & CIDR Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func calcRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(verbatim: value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
            
            Button {
                UIPasteboard.general.string = value
                ToastManager.shared.showCopied()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .higTouchTarget()
        }
    }
}
