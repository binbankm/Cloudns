import SwiftUI

struct CIDRCalculatorView: View {
    // MARK: - Properties
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
    
    // MARK: - Body
    var body: some View {
        ZStack {
            CloudnsColor.groupedBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: CloudnsSpacing.md) {
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
                .padding(.horizontal, CloudnsSpacing.md)
                .padding(.vertical, CloudnsSpacing.mdSmall)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Subnet & CIDR Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            HStack(spacing: CloudnsSpacing.smMd) {
                Image(systemName: "number.square.fill")
                    .font(.title3)
                    .foregroundStyle(CloudnsColor.brand)
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
            .padding(CloudnsSpacing.mdSmall)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            
            // Quick Presets
            ScrollView(.horizontal) {
                HStack(spacing: CloudnsSpacing.sm) {
                    ForEach(presetCIDRs, id: \.self) { preset in
                        Button {
                            viewModel.cidrInput = preset
                            viewModel.calculateSubnet()
                            HapticManager.selection()
                        } label: {
                            Text(preset)
                                .font(.caption.weight(.medium).monospacedDigit())
                                .padding(.horizontal, CloudnsSpacing.smMd)
                                .padding(.vertical, CloudnsSpacing.xs)
                                .background(viewModel.cidrInput == preset ? CloudnsColor.brand : CloudnsColor.brand.opacity(0.10))
                                .foregroundStyle(viewModel.cidrInput == preset ? .white : .blue)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 2. Range Card
    @ViewBuilder
    private func rangeCard(result: SubnetCalculationResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            HStack {
                Text("Subnet & Host Range")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                CloudnsBadge(.active("\(result.totalUsableHosts) Hosts"), isCompact: true)
            }
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.smMd) {
                calcRow(label: "Network Address", value: result.networkAddress)
                calcRow(label: "Broadcast Address", value: result.broadcastAddress)
                calcRow(label: "Usable Host Range", value: result.usableHostRange)
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 3. Properties Card
    @ViewBuilder
    private func propertiesCard(result: SubnetCalculationResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Masks & Network Properties")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.smMd) {
                calcRow(label: "Subnet Netmask", value: result.netmask)
                calcRow(label: "Wildcard Mask", value: result.wildcardMask)
                calcRow(label: "Prefix Length", value: "/\(result.prefixLength)")
                calcRow(label: "IP Class / Type", value: result.ipClass)
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 4. Bitmask Card
    @ViewBuilder
    private func bitmaskCard(result: SubnetCalculationResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.smMd) {
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
                        .foregroundStyle(CloudnsColor.brand)
                }
            }
            
            Divider()
            
            Text(result.binaryMask)
                .font(.caption.monospaced())
                .foregroundStyle(CloudnsColor.brand)
                .padding(CloudnsSpacing.smMd)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CloudnsColor.brand.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                .textSelection(.enabled)
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
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
        HStack(alignment: .top, spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(CloudnsColor.danger)
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Calculation Error")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
}
