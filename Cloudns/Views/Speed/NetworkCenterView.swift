import SwiftUI

struct NetworkCenterView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel = NetworkSettingsViewModel()
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.18), Color.cyan.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "globe.asia.australia.fill")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 4)
                    
                    Text("Network & Routing")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Manage network protocols and connectivity for \(zoneName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // MARK: - Error Banner
            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "exclamationmark.triangle.fill", color: .red, size: 28, cornerRadius: 6)
                        Text(verbatim: errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // MARK: - Core Protocols
            Section(
                header: Text("Core Protocols"),
                footer: Text("Modern network protocols accelerate delivery and provide better connection resilience.")
            ) {
                // IPv6
                Toggle(isOn: Binding(
                    get: { viewModel.ipv6 },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateIPv6(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "network", color: .blue, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("IPv6 Compatibility")
                                .font(.body)
                            Text("Enable IPv6 support and dual-stack gateway.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // WebSockets
                Toggle(isOn: Binding(
                    get: { viewModel.websockets },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateWebsockets(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "arrow.up.arrow.down.square.fill", color: .indigo, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("WebSockets")
                                .font(.body)
                            Text("Allow WebSockets traffic to your origin server.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - HTTP & Transport
            Section(
                header: Text("HTTP & Transport Acceleration"),
                footer: Text("HTTP/2 and HTTP/3 (QUIC) drastically reduce page load latency and handshake round trips.")
            ) {
                // HTTP/2
                Toggle(isOn: Binding(
                    get: { viewModel.http2 },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateHTTP2(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "bolt.horizontal.fill", color: .green, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("HTTP/2")
                                .font(.body)
                            Text("Accelerate page delivery with multiplexing.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // HTTP/3 (QUIC)
                Toggle(isOn: Binding(
                    get: { viewModel.http3 },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateHTTP3(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "bolt.fill", color: .orange, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("HTTP/3 (QUIC)")
                                    .font(.body)
                                HIGBadge(.active("Fastest"), isCompact: true)
                            }
                            Text("Next-generation QUIC transport with 0-RTT.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Advanced Routing
            Section(
                header: Text("Advanced Routing"),
                footer: Text("IP Geolocation includes visitor country code in the CF-IPCountry header.")
            ) {
                // IP Geolocation
                Toggle(isOn: Binding(
                    get: { viewModel.ipGeolocation },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateIPGeolocation(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "location.fill", color: .blue, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("IP Geolocation")
                                .font(.body)
                            Text("Attach visitor country code to headers.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Origin Max HTTP Version
                HStack(spacing: 12) {
                    ListRowIcon(icon: "server.rack", color: .purple, size: 28, cornerRadius: 6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Origin Max Protocol")
                            .font(.body)
                        Text("Maximum protocol version used to talk to origin server.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Origin Max Protocol", selection: Binding(
                        get: { viewModel.originMaxHttpVersion },
                        set: { val in
                            HIGFeedback.selection()
                            Task { await viewModel.updateOriginMaxHTTPVersion(zoneId: zoneId, version: val) }
                        }
                    )) {
                        Text("HTTP/2").tag("2")
                        Text("HTTP/1.1").tag("1")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .disabled(!viewModel.hasFetchedData)
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Network Settings…"))
            }
        }
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
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
