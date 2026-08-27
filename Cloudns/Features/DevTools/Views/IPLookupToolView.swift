import SwiftUI

struct IPLookupToolView: View {
    // MARK: - Properties
    @StateObject private var viewModel = IPLookupViewModel()
    @ObservedObject private var historyManager = DevToolsHistoryManager.shared
    @FocusState private var isFieldFocused: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack {
            CloudnsColor.groupedBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: CloudnsSpacing.md) {
                    // 1. Input Card
                    inputCard
                    
                    if viewModel.isLoading && viewModel.lookupResult == nil {
                        loadingSkeletonView
                    } else if let result = viewModel.lookupResult {
                        // 2. Identification Hero Card
                        identificationCard(result: result)
                        
                        // 3. ASN Card
                        asnCard(result: result)
                        
                        // 4. Geolocation Card
                        geoCard(result: result)
                    } else if let error = viewModel.errorMessage {
                        errorCard(message: error)
                    }
                }
                .padding(.horizontal, CloudnsSpacing.md)
                .padding(.vertical, CloudnsSpacing.mdSmall)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.ipInput.isEmpty {
                    HapticManager.impact(.light)
                    await viewModel.queryIP()
                }
            }
        }
        .navigationTitle("IP & ASN Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(spacing: CloudnsSpacing.mdMedium) {
            HStack(spacing: CloudnsSpacing.smMd) {
                Image(systemName: "location.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.teal)
                    .accessibilityHidden(true)
                
                TextField("e.g. 1.1.1.1 or 104.21.45.12", text: $viewModel.ipInput)
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)
                    .font(.body.monospacedDigit())
                    .submitLabel(.search)
                    .onSubmit {
                        performQuery()
                    }
                
                if !viewModel.ipInput.isEmpty {
                    Button {
                        viewModel.ipInput = ""
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
            
            QueryHistoryChipsView(
                history: historyManager.ipHistory,
                onSelect: { ip in
                    viewModel.ipInput = ip
                    performQuery()
                },
                onClear: {
                    historyManager.clearHistory(for: .ipLookup)
                }
            )
            
            CloudnsButton(
                viewModel.isLoading ? "Querying BGP & Geo..." : "Lookup IP Geolocation & ASN",
                icon: "location.fill",
                style: .primary(color: .teal),
                size: .regular,
                isFullWidth: true,
                isLoading: viewModel.isLoading,
                disabled: viewModel.ipInput.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                performQuery()
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Actions
    private func performQuery() {
        isFieldFocused = false
        guard !viewModel.ipInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        historyManager.recordQuery(viewModel.ipInput, for: .ipLookup)
        HapticManager.impact(.light)
        Task {
            await viewModel.queryIP()
        }
    }
    
    // MARK: - 2. Identification Card
    @ViewBuilder
    private func identificationCard(result: IPLookupResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            HStack {
                Text(result.countryFlag)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    Text(result.ip)
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(.primary)
                    
                    if let city = result.city, let country = result.country {
                        Text("\(city), \(country)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = result.ip
                    HapticManager.notification(.success)
                    CloudnsToastManager.shared.showCopied("IP copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                        .foregroundStyle(.teal)
                }
            }
            
            if let cloud = result.cloudProvider {
                Divider()
                HStack {
                    Image(systemName: result.isCloudflareAnycast ? "bolt.shield.fill" : "cloud.fill")
                        .foregroundStyle(result.isCloudflareAnycast ? .orange : .blue)
                    Text(cloud)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(result.isCloudflareAnycast ? .orange : .blue)
                    Spacer()
                    if result.isCloudflareAnycast {
                        CloudnsBadge(.active("Cloudflare Edge"), isCompact: true)
                    }
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 3. ASN Card
    @ViewBuilder
    private func asnCard(result: IPLookupResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Autonomous System (ASN)")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.smMd) {
                if let asn = result.asn {
                    HStack {
                        Text("ASN Number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        CloudnsBadge(.active(asn), isCompact: true)
                    }
                }
                if let org = result.org {
                    HStack {
                        Text("ISP / Organization")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(org)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 4. Geolocation Card
    @ViewBuilder
    private func geoCard(result: IPLookupResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Geographical Location")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.smMd) {
                if let country = result.country {
                    geoRow(title: "Country / Region", value: "\(result.countryFlag) \(country)")
                }
                if let region = result.region {
                    geoRow(title: "State / Province", value: region)
                }
                if let tz = result.timezone {
                    geoRow(title: "Timezone", value: tz)
                }
                if let lat = result.latitude, let lon = result.longitude {
                    geoRow(title: "Coordinates (Lat/Lon)", value: String(format: "%.4f, %.4f", lat, lon), isMono: true)
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    @ViewBuilder
    private func geoRow(title: LocalizedStringKey, value: String, isMono: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(isMono ? .subheadline.monospacedDigit() : .subheadline)
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Lookup Failed")
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
    
    // MARK: - Skeleton View
    private var loadingSkeletonView: some View {
        VStack(spacing: CloudnsSpacing.md) {
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
                HStack {
                    Circle().frame(width: CloudnsSize.iconHero, height: CloudnsSize.iconHero)
                    VStack(alignment: .leading) {
                        Text("1.1.1.1").font(.title3.weight(.bold))
                        Text("San Francisco, United States")
                    }
                }
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
            .skeletonLoading(true)
        }
    }
}
