import SwiftUI

struct CIDRCalculatorView: View {
    @StateObject private var viewModel = DevToolsViewModel()
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
            // Input & Presets
            Section(header: Text("CIDR Notation Input")) {
                HStack {
                    Image(systemName: "number.square.fill")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("192.168.1.0/24 or 2606:4700::/32", text: $viewModel.cidrInput)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
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
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(presetCIDRs, id: \.self) { preset in
                            Button {
                                viewModel.cidrInput = preset
                                viewModel.calculateSubnet()
                                HapticManager.selection()
                            } label: {
                                Text(preset)
                                    .font(.caption2.monospaced())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(viewModel.cidrInput == preset ? Color.blue : Color(.tertiarySystemFill))
                                    .foregroundStyle(viewModel.cidrInput == preset ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            if let result = viewModel.subnetResult {
                // 1. Network Address & Range
                Section(header: Text("Subnet & Host Range")) {
                    calcRow(label: "Network Address", value: result.networkAddress)
                    calcRow(label: "Broadcast Address", value: result.broadcastAddress)
                    calcRow(label: "Usable Host Range", value: result.usableHostRange)
                    calcRow(label: "Total Usable Hosts", value: result.totalUsableHosts, isHighlight: true)
                }
                
                // 2. Netmask & Class
                Section(header: Text("Masks & Properties")) {
                    calcRow(label: "Subnet Netmask", value: result.netmask)
                    calcRow(label: "Wildcard Mask", value: result.wildcardMask)
                    calcRow(label: "Prefix Length", value: "/\(result.prefixLength)")
                    calcRow(label: "IP Class / Type", value: result.ipClass)
                }
                
                // 3. Binary Bitmask
                Section(header: Text("Binary Bitmask Representation")) {
                    Text(result.binaryMask)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.blue)
                        .padding(.vertical, 2)
                        .textSelection(.enabled)
                }
            } else if let error = viewModel.subnetError {
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
        .navigationTitle("Subnet & CIDR Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func calcRow(label: LocalizedStringKey, value: String, isHighlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(isHighlight ? .subheadline.weight(.bold).monospaced() : .subheadline.monospaced())
                .foregroundStyle(isHighlight ? .green : .primary)
            
            Button {
                UIPasteboard.general.string = value
                HapticManager.notification(.success)
                ToastManager.shared.showCopied("Value copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
