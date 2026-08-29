import SwiftUI

struct IPLookupToolView: View {
    @StateObject private var viewModel = IPLookupViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // 1. Input Section
            Section(header: Text("Target IP Address"), footer: Text("Queries BGP routing registries, Autonomous System Numbers (ASN), ISP names & physical geolocation coordinates.")) {
                HStack(spacing: 10) {
                    Image(systemName: "location.circle.fill")
                        .font(.body)
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
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear input")
                    }
                }
                
                Button {
                    performQuery()
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(viewModel.isLoading ? "Querying BGP & Geo..." : "Lookup IP Geolocation & ASN")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.ipInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.lookupResult == nil {
                Section(header: Text("IP Identification")) {
                    identificationRows(result: IPLookupResult.placeholder)
                }
                .redacted(reason: .placeholder)
            } else if let result = viewModel.lookupResult {
                // 2. Identification Hero Section
                Section(header: Text("IP Identification")) {
                    identificationRows(result: result)
                }
                
                // 3. ASN Section
                Section(header: Text("Autonomous System (ASN)")) {
                    asnRows(result: result)
                }
                
                // 4. Geolocation Section
                Section(header: Text("Geographical Location")) {
                    geoRows(result: result)
                }
            } else if let error = viewModel.errorMessage {
                Section(header: Text("Error")) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            if !viewModel.ipInput.isEmpty {
                await viewModel.queryIP()
            }
        }
        .navigationTitle("IP & ASN Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performQuery() {
        isFieldFocused = false
        HIGFeedback.impact(.light)
        Task { await viewModel.queryIP() }
    }
    
    // MARK: - 2. Identification Rows
    @ViewBuilder
    private func identificationRows(result: IPLookupResult) -> some View {
        HStack {
            Text(result.countryFlag)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.ip)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                
                if let city = result.city, let country = result.country {
                    Text("\(city), \(country)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = result.ip
                ToastManager.shared.showCopied()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.teal)
            }
            .buttonStyle(.plain)
            .higTouchTarget()
        }
        
        if let cloud = result.cloudProvider {
            HStack {
                Image(systemName: result.isCloudflareAnycast ? "bolt.shield.fill" : "cloud.fill")
                    .foregroundStyle(result.isCloudflareAnycast ? .orange : .blue)
                Text(cloud)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(result.isCloudflareAnycast ? .orange : .blue)
                Spacer()
                if result.isCloudflareAnycast {
                    HIGBadge(.active("Cloudflare Edge"), isCompact: true)
                }
            }
        }
    }
    
    // MARK: - 3. ASN Rows
    @ViewBuilder
    private func asnRows(result: IPLookupResult) -> some View {
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
    
    // MARK: - 4. Geolocation Rows
    @ViewBuilder
    private func geoRows(result: IPLookupResult) -> some View {
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
}
