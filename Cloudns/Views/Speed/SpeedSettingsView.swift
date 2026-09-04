import SwiftUI

// MARK: - SpeedSettingsView
// Apple HIG Compliant Cloudflare Speed Optimization, Speed Brain, Brotli & WebP Polish (iOS 16.0+)

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
                        
                        Image(systemName: "bolt.badge.clock.fill")
                            .font(.title2.weight(.semibold))
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
                        ListRowIcon(icon: "exclamationmark.triangle.fill", color: .red)
                        Text(verbatim: errorMessage)
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateSpeedBrain(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Speed Brain Enabled" : "Speed Brain Disabled", icon: "brain.head.profile")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "brain.head.profile", color: .pink)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Speed Brain")
                                    .font(.body)
                                Text("AI Powered")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.14))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateFonts(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Fonts Acceleration Enabled" : "Fonts Acceleration Disabled", icon: "textformat")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "textformat", color: .blue)
                        VStack(alignment: .leading, spacing: 2) {
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateTieredCache(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Tiered Cache Enabled" : "Tiered Cache Disabled", icon: "square.stack.3d.up.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "square.stack.3d.up.fill", color: .indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Tiered Cache")
                                    .font(.body)
                                Text("Free")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.14))
                                    .clipShape(Capsule())
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateBrotli(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Brotli Enabled" : "Brotli Disabled", icon: "doc.zipper")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "doc.zipper", color: .teal)
                        VStack(alignment: .leading, spacing: 2) {
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateEarlyHints(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Early Hints Enabled" : "Early Hints Disabled", icon: "sparkles")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "sparkles", color: .yellow)
                        VStack(alignment: .leading, spacing: 2) {
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateRocketLoader(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Rocket Loader™ Enabled" : "Rocket Loader™ Disabled", icon: "flame.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "flame.fill", color: .orange)
                        VStack(alignment: .leading, spacing: 2) {
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
                    ListRowIcon(icon: "photo.fill", color: .green)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Polish (WebP)")
                                .font(.body)
                                .lineLimit(1)
                            Text("Pro")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.14))
                                .clipShape(Capsule())
                        }
                        Text("Automatic image compression and modern WebP conversion.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Polish", selection: Binding(
                        get: { viewModel.polish },
                        set: { val in
                            HapticManager.selection()
                            Task {
                                await viewModel.updatePolish(zoneId: zoneId, value: val)
                                ToastManager.shared.showSuccess("Polish Updated to \(val.capitalized)", icon: "photo.fill")
                            }
                        }
                    )) {
                        Text("Off").tag("off")
                        Text("Lossless").tag("lossless")
                        Text("Lossy").tag("lossy")
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
            loadingMessage: "Loading Speed Settings…"
        )
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
