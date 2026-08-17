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
                        .font(.system(size: 60, weight: .light))
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
            
            if !viewModel.hasFetchedData {
                // Skeleton: Core Protocols
                Section(header: Text("Core Protocols")) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                SkeletonBar(width: 140, height: 16, cornerRadius: 4)
                                SkeletonBar(width: 220, height: 12, cornerRadius: 4)
                            }
                            Spacer()
                            SkeletonBar(width: 50, height: 30, cornerRadius: 15)
                        }
                        .padding(.vertical, 4)
                        .skeletonLoading(true)
                    }
                }
                
                // Skeleton: Advanced Routing
                Section(header: Text("Advanced Routing")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonBar(width: 150, height: 16, cornerRadius: 4)
                            SkeletonBar(width: 240, height: 12, cornerRadius: 4)
                        }
                        Spacer()
                        SkeletonBar(width: 50, height: 30, cornerRadius: 15)
                    }
                    .padding(.vertical, 4)
                    .skeletonLoading(true)
                }
            } else {
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
                        HapticManager.impact(.light)
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
                        HapticManager.impact(.light)
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
                        HapticManager.impact(.light)
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
                        HapticManager.impact(.light)
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
            
            // Advanced Routing
            Section(header: Text("Advanced Routing")) {
                // IP Geolocation
                Toggle(isOn: Binding(
                    get: { viewModel.ipGeolocation },
                    set: { val in
                        HapticManager.impact(.light)
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
            }
        }
    }
    .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
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
        .toastContainer()
    }
}
