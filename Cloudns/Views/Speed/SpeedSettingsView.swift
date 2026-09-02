import SwiftUI

// MARK: - SpeedSettingsView
// Apple HIG Compliant Cloudflare Speed Optimization, Speed Brain, Brotli & WebP Polish

struct SpeedSettingsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SpeedSettingsViewModel()
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: HIGTokens.Spacing.md) {
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
                            .font(HIGTypography.title2.weight(.semibold))
                            .foregroundStyle(.purple)
                    }
                    .padding(.top, HIGTokens.Spacing.xs)
                    
                    Text("Speed Optimization")
                        .font(HIGTypography.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Supercharge site performance, CDN caching, and edge asset delivery.")
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HIGTokens.Spacing.md)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HIGTokens.Spacing.sm)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // MARK: - Error Banner
            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "exclamationmark.triangle.fill", color: HIGColors.error)
                        Text(verbatim: errorMessage)
                            .font(HIGTypography.subheadline)
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
                        Task {
                            await viewModel.updateSpeedBrain(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Speed Brain Enabled" : "Speed Brain Disabled", icon: "brain.head.profile")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "brain.head.profile", color: .pink)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            HStack(spacing: HIGTokens.Spacing.xs) {
                                Text("Speed Brain")
                                    .font(HIGTypography.body)
                                HIGBadge(.active("AI Powered"), isCompact: true)
                            }
                            Text("Speculative HTML prefetching for instant page navigation.")
                                .font(HIGTypography.caption)
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
                        Task {
                            await viewModel.updateFonts(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Fonts Acceleration Enabled" : "Fonts Acceleration Disabled", icon: "textformat")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "textformat", color: .blue)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Cloudflare Fonts")
                                .font(HIGTypography.body)
                            Text("Accelerate Google Fonts with privacy-preserving edge caching.")
                                .font(HIGTypography.caption)
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
                        Task {
                            await viewModel.updateTieredCache(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Tiered Cache Enabled" : "Tiered Cache Disabled", icon: "square.stack.3d.up.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "square.stack.3d.up.fill", color: .indigo)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            HStack(spacing: HIGTokens.Spacing.xs) {
                                Text("Tiered Cache")
                                    .font(HIGTypography.body)
                                HIGBadge(.free, isCompact: true)
                            }
                            Text("Use Cloudflare data centers as tiered caching layers.")
                                .font(HIGTypography.caption)
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
                        Task {
                            await viewModel.updateBrotli(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Brotli Enabled" : "Brotli Disabled", icon: "doc.zipper")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "doc.zipper", color: .teal)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Brotli Compression")
                                .font(HIGTypography.body)
                            Text("Speed up page load times for HTTPS traffic.")
                                .font(HIGTypography.caption)
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
                        Task {
                            await viewModel.updateEarlyHints(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Early Hints Enabled" : "Early Hints Disabled", icon: "sparkles")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "sparkles", color: .yellow)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Early Hints (HTTP 103)")
                                .font(HIGTypography.body)
                            Text("Preload linked critical assets while server compiles response.")
                                .font(HIGTypography.caption)
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
                        Task {
                            await viewModel.updateRocketLoader(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess(val ? "Rocket Loader™ Enabled" : "Rocket Loader™ Disabled", icon: "flame.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "flame.fill", color: .orange)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Rocket Loader™")
                                .font(HIGTypography.body)
                            Text("Prioritize website content by deferring JavaScript loading.")
                                .font(HIGTypography.caption)
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
                HStack(spacing: HIGTokens.Spacing.md) {
                    ListRowIcon(icon: "photo.fill", color: HIGColors.success)
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        HStack(spacing: HIGTokens.Spacing.xs) {
                            Text("Polish (WebP)")
                                .font(HIGTypography.body)
                                .lineLimit(1)
                            HIGBadge(.pro, isCompact: true)
                        }
                        Text("Automatic image compression and modern WebP conversion.")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Polish", selection: Binding(
                        get: { viewModel.polish },
                        set: { val in
                            HIGFeedback.selection()
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
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Speed Settings…"))
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
