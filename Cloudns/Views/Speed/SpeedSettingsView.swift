import SwiftUI

struct SpeedSettingsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SpeedSettingsViewModel()
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.18), Color.indigo.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "bolt.badge.automatic")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.purple)
                    }
                    .padding(.top, 4)
                    
                    Text("Speed Optimization")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Supercharge site performance, CDN caching, and edge asset delivery.")
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
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // MARK: - AI & Modern Acceleration
            Section(
                header: Text("Smart Acceleration"),
                footer: Text("Speed Brain uses predictive prefetching to load web pages before users click.")
            ) {
                // Speed Brain
                Toggle(isOn: Binding(
                    get: { viewModel.speedBrain },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateSpeedBrain(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "brain.head.profile", color: .pink, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("Speed Brain")
                                    .font(.body)
                                HIGBadge(.active("AI Powered"), isCompact: true)
                            }
                            Text("Speculative HTML prefetching for instant page navigation.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Cloudflare Fonts
                Toggle(isOn: Binding(
                    get: { viewModel.fonts },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateFonts(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "textformat", color: .blue, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Cloudflare Fonts")
                                .font(.body)
                            Text("Accelerate Google Fonts with privacy-preserving edge caching.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Tiered Cache
                Toggle(isOn: Binding(
                    get: { viewModel.tieredCache },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateTieredCache(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "square.stack.3d.up.fill", color: .indigo, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("Tiered Cache")
                                    .font(.body)
                                HIGBadge(.free, isCompact: true)
                            }
                            Text("Use Cloudflare data centers as tiered caching layers.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Compression & Scripts
            Section(
                header: Text("Compression & Script Loading"),
                footer: Text("Brotli offers higher compression over standard Gzip. Rocket Loader defers JavaScript execution.")
            ) {
                // Brotli
                Toggle(isOn: Binding(
                    get: { viewModel.brotli },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateBrotli(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "doc.zipper", color: .teal, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Brotli Compression")
                                .font(.body)
                            Text("Speed up page load times for HTTPS traffic.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Early Hints
                Toggle(isOn: Binding(
                    get: { viewModel.earlyHints },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateEarlyHints(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "sparkles", color: .yellow, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Early Hints (HTTP 103)")
                                .font(.body)
                            Text("Preload linked critical assets while server compiles response.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Rocket Loader
                Toggle(isOn: Binding(
                    get: { viewModel.rocketLoader },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateRocketLoader(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "flame.fill", color: .orange, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Rocket Loader™")
                                .font(.body)
                            Text("Prioritize website content by deferring JavaScript loading.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Image Optimization
            Section(
                header: Text("Image Optimization"),
                footer: Text("Cloudflare Polish optimizes images on the fly, reducing payload for mobile visitors.")
            ) {
                HStack(spacing: 12) {
                    ListRowIcon(icon: "photo.fill", color: .green, size: 28, cornerRadius: 6)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Polish (WebP)")
                                .font(.body)
                            HIGBadge(.pro, isCompact: true)
                        }
                        Text("Automatic image compression and modern WebP conversion.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("", selection: Binding(
                        get: { viewModel.polish },
                        set: { val in
                            HIGFeedback.selection()
                            Task { await viewModel.updatePolish(zoneId: zoneId, value: val) }
                        }
                    )) {
                        Text("Off").tag("off")
                        Text("Lossless").tag("lossless")
                        Text("Lossy").tag("lossy")
                    }
                    .pickerStyle(.menu)
                }
                .disabled(!viewModel.hasFetchedData)
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Speed Settings..."))
            }
        }
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
