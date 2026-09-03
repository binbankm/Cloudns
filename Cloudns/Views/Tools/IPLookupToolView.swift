import SwiftUI

// MARK: - IPLookupToolView
// Apple HIG Compliant IP Geolocation, BGP & ASN Lookup

struct IPLookupToolView: View {
    @StateObject private var viewModel = IPLookupViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // 1. Input Section
            Section(header: Text("Target IP Address"), footer: Text("Queries BGP routing registries, Autonomous System Numbers (ASN), ISP names & physical geolocation coordinates.")) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "location.circle.fill")
                        .font(HIGTypography.body)
                        .foregroundStyle(Color.higAccent)
                        .accessibilityHidden(true)
                    
                    TextField("e.g. 1.1.1.1 or 104.21.45.12", text: $viewModel.ipInput)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .font(HIGTypography.body.monospacedDigit())
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
                        .higTouchTarget(44)
                        .accessibilityLabel("Clear Input")
                    }
                }
                
                Button {
                    performQuery()
                } label: {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(viewModel.isLoading ? "Querying BGP & Geo…" : "Lookup IP Geolocation & ASN")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.ipInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading ? Color(.tertiaryLabel) : Color.higAccent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.higPressable)
                .disabled(viewModel.ipInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.lookupResult == nil {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Querying IP…")
                            .font(HIGTypography.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, HIGTokens.Spacing.sm)
                }
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
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HIGColors.error)
                        Text(verbatim: error)
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(HIGColors.error)
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
                .font(HIGTypography.title2)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(result.ip)
                    .font(HIGTypography.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                
                if let city = result.city, let country = result.country {
                    Text("\(city), \(country)")
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                HIGFeedback.copied()
                UIPasteboard.general.string = result.ip
                ToastManager.shared.showCopied("IP Copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(HIGTypography.caption)
                    .foregroundStyle(Color.higAccent)
            }
            .buttonStyle(.higPressable)
            .higTouchTarget(44)
            .accessibilityLabel("Copy IP Address")
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = result.ip
                ToastManager.shared.showCopied("IP Copied")
                HIGFeedback.copied()
            } label: {
                Label("Copy IP Address", systemImage: "doc.on.doc")
            }
        }
        
        if let cloud = result.cloudProvider {
            HStack {
                Image(systemName: result.isCloudflareAnycast ? "bolt.shield.fill" : "cloud.fill")
                    .foregroundStyle(result.isCloudflareAnycast ? .orange : Color.higAccent)
                Text(cloud)
                    .font(HIGTypography.subheadline.weight(.medium))
                    .foregroundStyle(result.isCloudflareAnycast ? .orange : Color.higAccent)
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
                Text("ASN")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: "AS\(asn)")
                    .font(HIGTypography.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = "AS\(asn)"
                    ToastManager.shared.showCopied("ASN Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy ASN", systemImage: "doc.on.doc")
                }
            }
        }
        
        if let org = result.org {
            HStack {
                Text("Organization")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(org)
                    .font(HIGTypography.subheadline)
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
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(result.countryFlag) \(country)")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        if let region = result.region {
            HStack {
                Text("Region / State")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(region)
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        if let city = result.city {
            HStack {
                Text("City")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(city)
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        if let tz = result.timezone {
            HStack {
                Text("Timezone")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(tz)
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
}
