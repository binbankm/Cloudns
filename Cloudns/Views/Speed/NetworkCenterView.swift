import SwiftUI

// MARK: - NetworkCenterView
// Apple HIG Compliant Cloudflare Network Protocols, HTTP/3 QUIC, IPv6 & Origin Routing (iOS 16.0+)

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
                            .font(.title2.weight(.semibold))
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
                        ListRowIcon(icon: "exclamationmark.triangle.fill", color: .red)
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateIPv6(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? LocalizedStringKey("IPv6 Enabled") : LocalizedStringKey("IPv6 Disabled"), icon: "network")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "network", color: .blue)
                        VStack(alignment: .leading, spacing: 2) {
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateWebsockets(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? LocalizedStringKey("WebSockets Enabled") : LocalizedStringKey("WebSockets Disabled"), icon: "arrow.up.arrow.down.square.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "arrow.up.arrow.down.square.fill", color: .indigo)
                        VStack(alignment: .leading, spacing: 2) {
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateHTTP2(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? LocalizedStringKey("HTTP/2 Enabled") : LocalizedStringKey("HTTP/2 Disabled"), icon: "bolt.horizontal.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "bolt.horizontal.fill", color: .green)
                        VStack(alignment: .leading, spacing: 2) {
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateHTTP3(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? LocalizedStringKey("HTTP/3 QUIC Enabled") : LocalizedStringKey("HTTP/3 QUIC Disabled"), icon: "bolt.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "bolt.fill", color: .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("HTTP/3 (QUIC)")
                                    .font(.body)
                                Text("Fastest")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.14))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateIPGeolocation(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? LocalizedStringKey("IP Geolocation Enabled") : LocalizedStringKey("IP Geolocation Disabled"), icon: "location.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "location.fill", color: .blue)
                        VStack(alignment: .leading, spacing: 2) {
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
                    ListRowIcon(icon: "server.rack", color: .purple)
                    VStack(alignment: .leading, spacing: 2) {
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
                            HapticManager.selection()
                            Task {
                                await viewModel.updateOriginMaxHTTPVersion(zoneId: zoneId, version: val)
                                ToastManager.shared.showSuccess("Origin Protocol Updated", icon: "server.rack")
                            }
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Network Settings…"
        )
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
