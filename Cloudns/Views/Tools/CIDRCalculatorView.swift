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
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "number.square.fill")
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
                        .accessibilityLabel("Clear Input")
                    }
                }
                
                // Quick Presets
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(presetCIDRs, id: \.self) { preset in
                            Button {
                                viewModel.cidrInput = preset
                                viewModel.calculateSubnet()
                                HapticManager.selection()
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
            } header: {
                Text("CIDR Notation / IP Subnet")
            } footer: {
                Text("Calculates usable IP host addresses, network broadcast bounds, netmasks & binary bitmasks.")
            }
            
            if let result = viewModel.subnetResult {
                // 2. Subnet Range Hero Section
                Section("Subnet & Host Range") {
                    HStack {
                        Text("Usable Hosts Count")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(result.totalUsableHosts) Hosts")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue.opacity(0.12)))
                    }
                    
                    calcRow(label: "Network Address", value: result.networkAddress)
                    calcRow(label: "Broadcast Address", value: result.broadcastAddress)
                    calcRow(label: "Usable Host Range", value: result.usableHostRange)
                }
                
                // 3. Properties Section
                Section("Masks & Network Properties") {
                    calcRow(label: "Subnet Netmask", value: result.netmask)
                    calcRow(label: "Wildcard Mask", value: result.wildcardMask)
                    calcRow(label: "Prefix Length", value: "/\(result.prefixLength)")
                    calcRow(label: "IP Class / Type", value: result.ipClass)
                }
                
                // 4. Binary Bitmask Section
                Section("Binary Bitmask") {
                    HStack {
                        Text(result.binaryMask)
                            .font(.caption.monospaced())
                            .foregroundStyle(.blue)
                            .textSelection(.enabled)
                        
                        Spacer()
                        
                        Button {
                            copyToClipboard(result.binaryMask, toast: "Binary Mask Copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else if let error = viewModel.subnetError {
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
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(verbatim: value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
            
            Button {
                copyToClipboard(value, toast: "\(value) Copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button {
                copyToClipboard(value, toast: "Value Copied")
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
        }
    }
}
