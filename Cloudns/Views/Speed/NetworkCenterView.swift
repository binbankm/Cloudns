import SwiftUI

struct NetworkCenterView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel = NetworkSettingsViewModel()
    
    var body: some View {
        List {
            // Network Graphic Header
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                        .padding(.top, 10)
                        .accessibilityHidden(true)
                    
                    Text("Network & Routing")
                        .font(.title2)
                    
                    Text("Manage network protocols and connectivity for \(zoneName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .accessibilityHidden(true)
                            Text(errorMessage)
                                .foregroundStyle(.primary)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Core Protocols
                Section(header: Text("Core Protocols")) {
                // IPv6
                Toggle(isOn: Binding(
                    get: { viewModel.ipv6 },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateIPv6(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IPv6 Compatibility")
                            .font(.body)
                        Text("Enable IPv6 support and gateway.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // WebSockets
                Toggle(isOn: Binding(
                    get: { viewModel.websockets },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateWebsockets(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WebSockets")
                            .font(.body)
                        Text("Allow WebSockets connections to your origin server.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // HTTP/2
                Toggle(isOn: Binding(
                    get: { viewModel.http2 },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateHTTP2(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HTTP/2")
                            .font(.body)
                        Text("Accelerate your website with HTTP/2.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // HTTP/3 (QUIC)
                Toggle(isOn: Binding(
                    get: { viewModel.http3 },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateHTTP3(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("HTTP/3 (with QUIC)")
                                .font(.body)
                            Image(systemName: "bolt.horizontal.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                        }
                        Text("Accelerate HTTP requests by using QUIC, which provides encryption and performance improvements compared to TCP and TLS.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Advanced Routing & Origin Protocol
            Section(header: Text("Advanced Routing & Origin"), footer: Text("Control geographic headers and edge-to-origin protocol versions.")) {
                // IP Geolocation
                Toggle(isOn: Binding(
                    get: { viewModel.ipGeolocation },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateIPGeolocation(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IP Geolocation Header")
                            .font(.body)
                        Text("Include the country code of the visitor location with all requests to your website.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Origin Max HTTP Version
                Picker(selection: Binding(
                    get: { viewModel.originMaxHttpVersion },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateOriginMaxHTTPVersion(zoneId: zoneId, version: val) }
                    }
                )) {
                    Text("HTTP/2 (Fastest)").tag("2")
                    Text("HTTP/1.1 (Legacy)").tag("1")
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Origin Max HTTP Version")
                                .font(.body)
                            HIGBadge(.free, isCompact: true)
                        }
                        Text("Maximum HTTP protocol version Cloudflare will use to connect to your origin server.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            } else if viewModel.isLoading {
                Section(header: Text("Core Protocols")) {
                    Toggle("IPv6 Compatibility", isOn: .constant(true))
                        .redacted(reason: .placeholder)
                    Toggle("WebSockets", isOn: .constant(true))
                        .redacted(reason: .placeholder)
                    Toggle("HTTP/2", isOn: .constant(true))
                        .redacted(reason: .placeholder)
                }
            }
        }
        .listStyle(.insetGrouped)
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
