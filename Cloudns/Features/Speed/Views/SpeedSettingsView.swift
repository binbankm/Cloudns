import SwiftUI

struct SpeedSettingsView: View {
    // MARK: - Properties
    let zoneId: String
    
    @StateObject private var viewModel = SpeedSettingsViewModel()
    
    // MARK: - Body
    var body: some View {
        List {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        HStack(spacing: CloudnsSpacing.smMd) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(CloudnsColor.danger)
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
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            HStack(spacing: CloudnsSpacing.sm) {
                                Image(systemName: "bolt.badge.sparkle")
                                    .foregroundStyle(CloudnsColor.ai)
                                Text("Speed Brain")
                                    .font(.body.weight(.medium))
                                CloudnsBadge(.free, isCompact: true)
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
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            HStack(spacing: CloudnsSpacing.sm) {
                                Image(systemName: "textformat.size")
                                    .foregroundStyle(.teal)
                                Text("Cloudflare Fonts")
                                    .font(.body.weight(.medium))
                                CloudnsBadge(.free, isCompact: true)
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
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            HStack(spacing: CloudnsSpacing.sm) {
                                Image(systemName: "network")
                                    .foregroundStyle(CloudnsColor.brandAccent)
                                Text("Tiered Cache")
                                    .font(.body.weight(.medium))
                                CloudnsBadge(.free, isCompact: true)
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
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
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
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            HStack(spacing: CloudnsSpacing.sm) {
                                Text("Rocket Loader™")
                                    .font(.body)
                                Image(systemName: "hare.fill")
                                    .font(.caption)
                                    .foregroundStyle(CloudnsColor.brandAccent)
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
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
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
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            HStack(spacing: CloudnsSpacing.sm) {
                                Text("Polish (WebP)")
                                    .font(.body)
                                CloudnsBadge(.pro, isCompact: true)
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
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            Text("Speed Brain")
                            Text("Predictive prefetching via W3C Speculation Rules.")
                        }
                    }
                    .skeletonLoading(true)
                    
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            Text("Cloudflare Fonts")
                            Text("Privacy-preserving edge proxy for Google Fonts.")
                        }
                    }
                    .skeletonLoading(true)
                }
                
                Section(header: Text("Asset Optimization")) {
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            Text("Brotli")
                            Text("Speed up page load times for your visitor's HTTPS traffic.")
                        }
                    }
                    .skeletonLoading(true)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
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
