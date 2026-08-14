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
                            .foregroundColor(.blue)
                        
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
                                    .foregroundColor(.secondary)
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
                                .font(.body.weight(.semibold))
                                .foregroundColor(.blue)
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
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(res.ip)
                                .font(.body.monospaced().bold())
                                .foregroundColor(.primary)
                        }
                        
                        if let country = res.country {
                            HStack {
                                Text("Country / Region")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(country) \(res.countryCode ?? "")")
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let city = res.city {
                            HStack {
                                Text("City")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(city)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let tz = res.timezone {
                            HStack {
                                Text("Timezone")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(tz)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    Section(header: Text("Autonomous System (ASN)")) {
                        if let asn = res.asn {
                            HStack {
                                Text("ASN")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(asn)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        if let org = res.org {
                            HStack {
                                Text("ISP / Organization")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(org)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                } else if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("IP & ASN Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }
}
