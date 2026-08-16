import SwiftUI

struct SpeedSettingsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SpeedSettingsViewModel()
    
    var body: some View {
        List {
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
                
                Toggle("CSS", isOn: Binding(
                    get: { viewModel.minifyCSS },
                    set: { val in
                        HapticManager.impact(.light)
                        viewModel.minifyCSS = val
                        Task { await viewModel.updateMinify(zoneId: zoneId, css: val, html: viewModel.minifyHTML, js: viewModel.minifyJS) }
                    }
                ))
                
                Toggle("HTML", isOn: Binding(
                    get: { viewModel.minifyHTML },
                    set: { val in
                        HapticManager.impact(.light)
                        viewModel.minifyHTML = val
                        Task { await viewModel.updateMinify(zoneId: zoneId, css: viewModel.minifyCSS, html: val, js: viewModel.minifyJS) }
                    }
                ))
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
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .skeletonLoading(!viewModel.hasFetchedData)
        .navigationTitle("Speed Optimization")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
        .toastContainer()
    }
}
