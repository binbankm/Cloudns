import SwiftUI

struct CFTraceToolView: View {
    @StateObject private var viewModel = CFTraceViewModel()
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        List {
            // Section: Host Input
            Section(header: Text("Trace Host")) {
                HStack {
                    Image(systemName: "network")
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    
                    TextField("www.cloudflare.com", text: $viewModel.host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.queryTrace() }
                        }
                }
                
                Button {
                    isFieldFocused = false
                    HapticManager.impact(.light)
                    Task { await viewModel.queryTrace() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text("Trace PoP & Network")
                            .font(.body)
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                }
                .disabled(viewModel.host.isEmpty || viewModel.isLoading)
            }
            
            if !viewModel.traceFields.isEmpty {
                traceSections(fields: viewModel.traceFields, colo: viewModel.coloCode, ip: viewModel.clientIp, loc: viewModel.locCountry, warp: viewModel.warpStatus)
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
        .navigationTitle("Cloudflare Trace")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.traceFields.isEmpty {
                await viewModel.queryTrace()
            }
        }
    }
    
    @ViewBuilder
    private func traceSections(fields: [HTTPHeaderItem], colo: String?, ip: String?, loc: String?, warp: String?) -> some View {
        if let colo = colo {
            Section(header: Text("Connection Summary")) {
                HStack {
                    Text("Edge PoP Data Center")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let city = popCityName(for: colo) {
                        Text(city)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    CloudnsBadge(.proxied(colo), isCompact: true)
                }
                
                if let ip = ip {
                    HStack {
                        Text("Client IP")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(ip)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
                
                if let loc = loc {
                    HStack {
                        Text("Country / Region")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(loc)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let warp = warp {
                    HStack {
                        Text("Cloudflare WARP")
                            .foregroundStyle(.secondary)
                        Spacer()
                        CloudnsBadge(warp == "on" || warp == "plus" ? .active("WARP \(warp.uppercased())") : .custom(color: .secondary, text: warp.uppercased()), isCompact: true)
                    }
                }
            }
        }
        
        Section(header: HStack {
            Text("All Trace Fields (\(fields.count))")
            Spacer()
            Button {
                let text = fields.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
                UIPasteboard.general.string = text
                HapticManager.notification(.success)
                ToastManager.shared.showCopied("Trace copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .accessibilityLabel("Copy all trace fields")
        }) {
            ForEach(fields) { field in
                HStack {
                    Text(field.key)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(field.value)
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private func popCityName(for colo: String) -> String? {
        let cities: [String: String] = [
            "HKG": "Hong Kong", "SIN": "Singapore", "NRT": "Tokyo Narita", "HND": "Tokyo Haneda",
            "KIX": "Osaka", "TPE": "Taipei", "ICN": "Seoul", "SFO": "San Francisco",
            "LAX": "Los Angeles", "SJC": "San Jose", "SEA": "Seattle", "ORD": "Chicago",
            "DFW": "Dallas", "IAD": "Washington D.C.", "EWR": "Newark", "JFK": "New York",
            "LHR": "London", "FRA": "Frankfurt", "CDG": "Paris", "AMS": "Amsterdam",
            "SYD": "Sydney", "MEL": "Melbourne", "BNE": "Brisbane", "AKL": "Auckland",
            "YYZ": "Toronto", "YVR": "Vancouver", "DXB": "Dubai", "BOM": "Mumbai", "DEL": "New Delhi"
        ]
        return cities[colo.uppercased()]
    }
}
