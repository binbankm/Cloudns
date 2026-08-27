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
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Input Card
                    inputCard
                    
                    if let result = viewModel.subnetResult {
                        // 2. Subnet Range Hero Card
                        rangeCard(result: result)
                        
                        // 3. Properties Card
                        propertiesCard(result: result)
                        
                        // 4. Binary Bitmask Card
                        bitmaskCard(result: result)
                    } else if let error = viewModel.subnetError {
                        errorCard(message: error)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Subnet & CIDR Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "number.square.fill")
                    .font(.title3)
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
                    .accessibilityLabel("Clear input")
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
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
                                .background(viewModel.cidrInput == preset ? Color.blue : Color.blue.opacity(0.10))
                                .foregroundStyle(viewModel.cidrInput == preset ? .white : .blue)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 2. Range Card
    @ViewBuilder
    private func rangeCard(result: SubnetCalculationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subnet & Host Range")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                CloudnsBadge(.active("\(result.totalUsableHosts) Hosts"), isCompact: true)
            }
            
            Divider()
            
            VStack(spacing: 10) {
                calcRow(label: "Network Address", value: result.networkAddress)
                calcRow(label: "Broadcast Address", value: result.broadcastAddress)
                calcRow(label: "Usable Host Range", value: result.usableHostRange)
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 3. Properties Card
    @ViewBuilder
    private func propertiesCard(result: SubnetCalculationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Masks & Network Properties")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 10) {
                calcRow(label: "Subnet Netmask", value: result.netmask)
                calcRow(label: "Wildcard Mask", value: result.wildcardMask)
                calcRow(label: "Prefix Length", value: "/\(result.prefixLength)")
                calcRow(label: "IP Class / Type", value: result.ipClass)
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 4. Bitmask Card
    @ViewBuilder
    private func bitmaskCard(result: SubnetCalculationResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Binary Bitmask")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    UIPasteboard.general.string = result.binaryMask
                    HapticManager.notification(.success)
                    CloudnsToastManager.shared.showCopied("Binary mask copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            Divider()
            
            Text(result.binaryMask)
                .font(.caption.monospaced())
                .foregroundStyle(.blue)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .textSelection(.enabled)
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    @ViewBuilder
    private func calcRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
            
            Button {
                UIPasteboard.general.string = value
                HapticManager.notification(.success)
                CloudnsToastManager.shared.showCopied("Value copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Calculation Error")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
}
