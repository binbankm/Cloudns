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
                
                // Advanced Optimizations
                Section(header: Text("Speed & Optimization"), footer: Text("Configure CDN edge acceleration and asset optimizations for faster page loads.")) {
                    // Brotli
                    Toggle(isOn: Binding(
                        get: { viewModel.brotli },
                        set: { val in
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
                Section(header: Text("Speed & Optimization")) {
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
                    
                    Toggle(isOn: .constant(true)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Early Hints")
                            Text("Help browsers start loading assets sooner.")
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
