import SwiftUI

struct IPLookupToolView: View {
    @StateObject private var viewModel = IPLookupViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Input Card
                    inputCard
                    
                    if viewModel.isLoading && viewModel.lookupResult == nil {
                        identificationCard(result: IPLookupResult.placeholder)
                            .redacted(reason: .placeholder)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.ipInput.isEmpty {
                    await viewModel.queryIP()
                }
            }
        }
        .navigationTitle("IP & ASN Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Input Card
    private var inputCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
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
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Button {
                performQuery()
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text(viewModel.isLoading ? "Querying BGP & Geo..." : "Lookup IP Geolocation & ASN")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .controlSize(.regular)
            .disabled(viewModel.ipInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func performQuery() {
        isFieldFocused = false
        HIGFeedback.impact(.light)
        Task { await viewModel.queryIP() }
    }
    
    // MARK: - 2. Identification Card
    @ViewBuilder
    private func identificationCard(result: IPLookupResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.countryFlag)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 2) {
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
                    HIGFeedback.success()
                    HIGFeedback.impact(.light)
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
                        HIGBadge(.active("Cloudflare Edge"), isCompact: true)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - 3. ASN Card
    @ViewBuilder
    private func asnCard(result: IPLookupResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Autonomous System (ASN)")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 10) {
                if let asn = result.asn {
                    HStack {
                        Text("ASN Number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HIGBadge(.active(asn), isCompact: true)
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
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - 4. Geolocation Card
    @ViewBuilder
    private func geoCard(result: IPLookupResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Geographical Location")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 10) {
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
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Lookup Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
