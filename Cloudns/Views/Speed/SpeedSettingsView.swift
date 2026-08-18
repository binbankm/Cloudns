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
                
                // Auto Minify
                Section(header: Text("Auto Minify")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reduce the file size of source code on your website.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Toggle("JavaScript", isOn: Binding(
                        get: { viewModel.minifyJS },
                        set: { val in
                            HapticManager.impact(.light)
                            viewModel.minifyJS = val
                            Task { await viewModel.updateMinify(zoneId: zoneId, css: viewModel.minifyCSS, html: viewModel.minifyHTML, js: val) }
                        }
                    ))
                    .disabled(!viewModel.hasFetchedData)
                    
                    Toggle("CSS", isOn: Binding(
                        get: { viewModel.minifyCSS },
                        set: { val in
                            HapticManager.impact(.light)
                            viewModel.minifyCSS = val
                            Task { await viewModel.updateMinify(zoneId: zoneId, css: val, html: viewModel.minifyHTML, js: viewModel.minifyJS) }
                        }
                    ))
                    .disabled(!viewModel.hasFetchedData)
                    
                    Toggle("HTML", isOn: Binding(
                        get: { viewModel.minifyHTML },
                        set: { val in
                            HapticManager.impact(.light)
                            viewModel.minifyHTML = val
                            Task { await viewModel.updateMinify(zoneId: zoneId, css: viewModel.minifyCSS, html: val, js: viewModel.minifyJS) }
                        }
                    ))
                    .disabled(!viewModel.hasFetchedData)
                }
                
                // Advanced Optimizations
                Section(header: Text("Advanced Optimizations")) {
                    // Brotli
                    Toggle(isOn: Binding(
                        get: { viewModel.brotli },
                        set: { val in
                            HapticManager.impact(.light)
                            Task { await viewModel.updateBrotli(zoneId: zoneId, isOn: val) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Brotli")
                                .font(.body)
                            Text("Speed up page load times for your visitor's HTTPS traffic by applying Brotli compression.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    // Rocket Loader
                    Toggle(isOn: Binding(
                        get: { viewModel.rocketLoader },
                        set: { val in
                            HapticManager.impact(.light)
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
                            Text("Improve the paint time for pages which include JavaScript.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                    
                    // Early Hints
                    Toggle(isOn: Binding(
                        get: { viewModel.earlyHints },
                        set: { val in
                            HapticManager.impact(.light)
                            Task { await viewModel.updateEarlyHints(zoneId: zoneId, isOn: val) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Early Hints")
                                .font(.body)
                            Text("Help browsers start loading assets sooner by responding with 103 Early Hints before the full response is ready.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!viewModel.hasFetchedData)
                }
            } else if viewModel.isLoading {
                Section(header: Text("Auto Minify")) {
                    Toggle("JavaScript", isOn: .constant(true))
                        .skeletonLoading(true)
                    Toggle("CSS", isOn: .constant(true))
                        .skeletonLoading(true)
                    Toggle("HTML", isOn: .constant(true))
                        .skeletonLoading(true)
                }
                
                Section(header: Text("Advanced Optimizations")) {
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Brotli")
                            Text("Speed up page load times for your visitor's HTTPS traffic.")
                        }
                    }
                    .skeletonLoading(true)
                    
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rocket Loader™")
                            Text("Improve the paint time for pages which include JavaScript.")
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
