import SwiftUI

struct IPLookupToolView: View {
    @StateObject private var viewModel = IPLookupViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Section: Input
            Section(header: Text("Query Target")) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("e.g. 1.1.1.1 or cloudflare.com", text: $viewModel.ipInput)
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
                        .accessibilityLabel("Clear input")
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
                            Image(systemName: "network.badge.shield.half.filled")
                        }
                        Text("Query IP / ASN Info")
                            .font(.body)
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
                .disabled(viewModel.ipInput.isEmpty || viewModel.isLoading)
            }
            
            if let res = viewModel.lookupResult {
                ipLookupSections(res)
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("IP & ASN Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func ipLookupSections(_ res: IPLookupResult) -> some View {
        Section(header: Text("IP & Geolocation")) {
            HStack {
                Text("IP Address")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(res.ip)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.primary)
            }
            
            if let city = res.city, let country = res.country {
                HStack {
                    Text("Location")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(city), \(country)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            
            if let region = res.region {
                HStack {
                    Text("Region")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(region)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            
            if let tz = res.timezone {
                HStack {
                    Text("Timezone")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(tz)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        // Section: ASN & Network
        Section(header: Text("Network & Autonomous System (ASN)")) {
            if let asn = res.asn {
                HStack {
                    Text("ASN")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(asn)
                        .font(.subheadline.monospaced().weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            if let org = res.org {
                HStack {
                    Text("ISP / Organization")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(org)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}
