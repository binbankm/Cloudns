import SwiftUI

struct SpeedSettingsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SpeedSettingsViewModel()
    
    var body: some View {
        List {
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
                
                // 1. Next-Gen Acceleration
                Section(header: Text("Next-Gen Acceleration"), footer: Text("Modern edge protocols and AI-powered speculation for sub-second page loads.")) {
                    // Speed Brain
                    Toggle(isOn: Binding(
                        get: { viewModel.speedBrain },
                        set: { val in
                            Task { await viewModel.updateSpeedBrain(zoneId: zoneId, isOn: val) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.badge.sparkle")
                                    .foregroundStyle(.purple)
                                Text("Speed Brain")
                                    .font(.body.weight(.medium))
                                HIGBadge(.free, isCompact: true)
                            }
                            Text("Predictive prefetching via W3C Speculation Rules for instantaneous zero-latency page navigations.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    // Cloudflare Fonts
                    Toggle(isOn: Binding(
                        get: { viewModel.fonts },
                        set: { val in
                            Task { await viewModel.updateFonts(zoneId: zoneId, isOn: val) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "textformat.size")
                                    .foregroundStyle(.teal)
                                Text("Cloudflare Fonts")
                                    .font(.body.weight(.medium))
                                HIGBadge(.free, isCompact: true)
                            }
                            Text("Privacy-preserving edge proxy for Google Fonts to eliminate third-party tracking and layout shift.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    // Tiered Cache
                    Toggle(isOn: Binding(
                        get: { viewModel.tieredCache },
                        set: { val in
                            Task { await viewModel.updateTieredCache(zoneId: zoneId, isOn: val) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "network")
                                    .foregroundStyle(.orange)
                                Text("Tiered Cache")
                                    .font(.body.weight(.medium))
                                HIGBadge(.free, isCompact: true)
                            }
                            Text("Smart regional cache tiering to reduce origin server load and drastically improve global cache hit ratios.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                }
                
                // 2. Asset Optimizations
                Section(header: Text("Asset Optimization"), footer: Text("Configure CDN edge compression and runtime asset improvements.")) {
                    // Brotli
                    Toggle(isOn: Binding(
                        get: { viewModel.brotli },
                        set: { val in
                            Task { await viewModel.updateBrotli(zoneId: zoneId, isOn: val) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Brotli Compression")
                                .font(.body)
                            Text("Speed up HTTPS page load times by applying modern Brotli compression.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    // Rocket Loader
                    Toggle(isOn: Binding(
                        get: { viewModel.rocketLoader },
                        set: { val in
                            Task { await viewModel.updateRocketLoader(zoneId: zoneId, isOn: val) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Rocket Loader™")
                                    .font(.body)
                                Image(systemName: "hare.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .accessibilityHidden(true)
                            }
                            Text("Improve paint times for pages containing heavy JavaScript.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    // Early Hints
                    Toggle(isOn: Binding(
                        get: { viewModel.earlyHints },
                        set: { val in
                            Task { await viewModel.updateEarlyHints(zoneId: zoneId, isOn: val) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("103 Early Hints")
                                .font(.body)
                            Text("Help browsers start loading linked CSS/JS assets before the HTML response finishes rendering.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                }
                
                // 3. Image Optimization (Polish)
                Section(header: Text("Image Optimization"), footer: Text("Cloudflare Polish optimizes images on the fly, reducing byte payload for mobile visitors.")) {
                    Picker(selection: Binding(
                        get: { viewModel.polish },
                        set: { val in
                            Task { await viewModel.updatePolish(zoneId: zoneId, value: val) }
                        }
                    )) {
                        Text("Off").tag("off")
                        Text("Lossless (Fast)").tag("lossless")
                        Text("Lossy (Maximum Compression)").tag("lossy")
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Polish (WebP)")
                                    .font(.body)
                                HIGBadge(.pro, isCompact: true)
                            }
                            Text("Automatic image compression and WebP conversion.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                }
            } else if viewModel.isLoading {
                Section(header: Text("Next-Gen Acceleration")) {
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Speed Brain")
                            Text("Predictive prefetching via W3C Speculation Rules.")
                        }
                    }
                    .redacted(reason: .placeholder)
                    
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cloudflare Fonts")
                            Text("Privacy-preserving edge proxy for Google Fonts.")
                        }
                    }
                    .redacted(reason: .placeholder)
                }
                
                Section(header: Text("Asset Optimization")) {
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Brotli")
                            Text("Speed up page load times for your visitor's HTTPS traffic.")
                        }
                    }
                    .redacted(reason: .placeholder)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .navigationTitle("Speed Optimization")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
    }
}
