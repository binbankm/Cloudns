import SwiftUI

// MARK: - IPLookupToolView
// Apple HIG Compliant IP Geolocation, BGP & ASN Lookup

struct IPLookupToolView: View {
    @StateObject private var viewModel = IPLookupViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // 1. Input Section
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "location.circle.fill")
                        .foregroundStyle(.tint)
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
                        .accessibilityLabel("Clear Input")
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
                        Text(viewModel.isLoading ? "Querying BGP & Geo…" : "Lookup IP Geolocation & ASN")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.ipInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            } header: {
                Text("Target IP Address")
            } footer: {
                Text("Queries BGP routing registries, Autonomous System Numbers (ASN), ISP names & physical geolocation coordinates.")
            }
            
            if viewModel.isLoading && viewModel.lookupResult == nil {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Querying IP…")
                            .padding(.vertical, 8)
                        Spacer()
                    }
                }
            } else if let result = viewModel.lookupResult {
                // 2. Identification Hero Section
                Section("IP Identification") {
                    identificationRows(result: result)
                }
                
                // 3. ASN Section
                Section("Autonomous System (ASN)") {
                    asnRows(result: result)
                }
                
                // 4. Geolocation Section
                Section("Geographical Location") {
                    geoRows(result: result)
                }
            } else if let error = viewModel.errorMessage {
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
        HapticManager.impact(.light)
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
                copyToClipboard(result.ip, toast: "IP Copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy IP Address")
        }
        .contextMenu {
            Button {
                copyToClipboard(result.ip, toast: "IP Copied")
            } label: {
                Label("Copy IP Address", systemImage: "doc.on.doc")
            }
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
                    Text("Cloudflare Edge")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                }
            }
        }
    }
    
    // MARK: - 3. ASN Rows
    @ViewBuilder
    private func asnRows(result: IPLookupResult) -> some View {
        if let asn = result.asn {
            HStack {
                Text("ASN")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: "AS\(asn)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .contextMenu {
                Button {
                    copyToClipboard("AS\(asn)", toast: "ASN Copied")
                } label: {
                    Label("Copy ASN", systemImage: "doc.on.doc")
                }
            }
        }
        
        if let org = result.org {
            HStack {
                Text("Organization")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(org)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: - 4. Geolocation Rows
    @ViewBuilder
    private func geoRows(result: IPLookupResult) -> some View {
        if let country = result.country {
            HStack {
                Text("Country")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(result.countryFlag) \(country)")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        if let region = result.region {
            HStack {
                Text("Region / State")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(region)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        if let city = result.city {
            HStack {
                Text("City")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(city)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        if let tz = result.timezone {
            HStack {
                Text("Timezone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(tz)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
}
