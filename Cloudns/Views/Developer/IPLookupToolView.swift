import SwiftUI

struct IPLookupToolView: View {
    @StateObject private var viewModel = IPLookupViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Target IP Input
            Section(header: Text("Target IP Address or Hostname")) {
                HStack {
                    Image(systemName: "location.circle")
                        .foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    
                    TextField("e.g. 1.1.1.1 or 104.21.45.12", text: $viewModel.ipInput)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.queryIP() }
                        }
                    
                    if !viewModel.ipInput.isEmpty {
                        Button {
                            viewModel.ipInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Button {
                    isFieldFocused = false
                    HapticManager.impact(.light)
                    Task { await viewModel.queryIP() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text("Lookup IP Geolocation & ASN")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.teal)
                        Spacer()
                    }
                }
                .disabled(viewModel.ipInput.isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.lookupResult == nil {
                ipDetailsSection(result: IPLookupResult.placeholder)
                    .skeletonLoading(true)
            } else if let result = viewModel.lookupResult {
                ipDetailsSection(result: result)
            } else if let error = viewModel.errorMessage {
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
        .navigationTitle("IP & ASN Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func ipDetailsSection(result: IPLookupResult) -> some View {
        // 1. IP & Cloud Provider Identification
        Section(header: Text("Network Identification")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(result.countryFlag)
                        .font(.title)
                    
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
                        HapticManager.notification(.success)
                        ToastManager.shared.showCopied("IP copied to clipboard")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(.teal)
                    }
                    .buttonStyle(.plain)
                }
                
                if let cloud = result.cloudProvider {
                    HStack {
                        Image(systemName: result.isCloudflareAnycast ? "bolt.shield.fill" : "cloud.fill")
                            .foregroundStyle(result.isCloudflareAnycast ? .orange : .blue)
                        Text(cloud)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(result.isCloudflareAnycast ? .orange : .blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)
        }
        
        // 2. ASN & BGP Route Details
        Section(header: Text("BGP Autonomous System (ASN)")) {
            if let asn = result.asn {
                HStack {
                    Text("ASN Number")
                        .foregroundStyle(.secondary)
                    Spacer()
                    CloudnsBadge(.active(asn), isCompact: true)
                }
            }
            
            if let org = result.org {
                HStack {
                    Text("ISP / Organization")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(org)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        
        // 3. Geolocation & Coordinates
        Section(header: Text("Geographical Location")) {
            if let country = result.country {
                HStack {
                    Text("Country / Region")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(result.countryFlag) \(country)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            
            if let region = result.region {
                HStack {
                    Text("State / Province")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(region)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            
            if let tz = result.timezone {
                HStack {
                    Text("Timezone")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(tz)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            
            if let lat = result.latitude, let lon = result.longitude {
                HStack {
                    Text("Coordinates (Lat / Lon)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.4f, %.4f", lat, lon))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}
