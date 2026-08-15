import SwiftUI

struct IPLookupToolView: View {
    @StateObject private var viewModel = IPLookupViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            List {
                // Section: Input
                Section(header: Text("Query Target")) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.blue)
                        
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
                                    .accessibilityLabel("清除输入")
                            }
                        }
                    }
                    
                    Button {
                        isFieldFocused = false
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
                
                // Section: Results
                if let res = viewModel.lookupResult {
                    Section(header: Text("IP & Geolocation")) {
                        HStack {
                            Text("IP Address")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(res.ip)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        
                        if let country = res.country {
                            HStack {
                                Text("Country / Region")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(country) \(res.countryCode ?? "")")
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        if let city = res.city {
                            HStack {
                                Text("City")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(city)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        if let tz = res.timezone {
                            HStack {
                                Text("Timezone")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(tz)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    
                    Section(header: Text("Autonomous System (ASN)")) {
                        if let asn = res.asn {
                            HStack {
                                Text("ASN")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(asn)
                                    .font(.caption.monospacedDigit())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundStyle(.blue)
                                    .cornerRadius(4)
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
                } else if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("IP & ASN Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }
}
