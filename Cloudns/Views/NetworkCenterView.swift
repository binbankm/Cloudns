import SwiftUI

struct NetworkCenterView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel = NetworkSettingsViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Network Graphic Header
                    VStack(spacing: 12) {
                        Image(systemName: "network")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.blue)
                            .padding(.top, 10)
                        
                        Text("Network & Routing")
                            .font(.title2.bold())
                        
                        Text("Manage network protocols and connectivity for \(zoneName).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Core Protocols
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // IPv6
                        Toggle(isOn: Binding(
                            get: { viewModel.ipv6 },
                            set: { val in
                                Task { await viewModel.updateIPv6(zoneId: zoneId, isOn: val) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("IPv6 Compatibility")
                                    .font(.body)
                                Text("Enable IPv6 support and gateway.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // WebSockets
                        Toggle(isOn: Binding(
                            get: { viewModel.websockets },
                            set: { val in
                                Task { await viewModel.updateWebsockets(zoneId: zoneId, isOn: val) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WebSockets")
                                    .font(.body)
                                Text("Allow WebSockets connections to your origin server.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // HTTP/2
                        Toggle(isOn: Binding(
                            get: { viewModel.http2 },
                            set: { val in
                                Task { await viewModel.updateHTTP2(zoneId: zoneId, isOn: val) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HTTP/2")
                                    .font(.body)
                                Text("Accelerate your website with HTTP/2.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // HTTP/3 (QUIC)
                        Toggle(isOn: Binding(
                            get: { viewModel.http3 },
                            set: { val in
                                Task { await viewModel.updateHTTP3(zoneId: zoneId, isOn: val) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("HTTP/3 (with QUIC)")
                                        .font(.body)
                                    Image(systemName: "bolt.horizontal.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                Text("Accelerate HTTP requests by using QUIC, which provides encryption and performance improvements compared to TCP and TLS.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Advanced Routing
                    VStack(alignment: .leading, spacing: 0) {
                        // IP Geolocation
                        Toggle(isOn: Binding(
                            get: { viewModel.ipGeolocation },
                            set: { val in
                                Task { await viewModel.updateIPGeolocation(zoneId: zoneId, isOn: val) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("IP Geolocation Header")
                                    .font(.body)
                                Text("Include the country code of the visitor location with all requests to your website.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                }
                .padding()
                .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
                .disabled(!viewModel.hasFetchedData || viewModel.isLoading)
            }
            .refreshable {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
        .navigationTitle("Network")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
    }
}
