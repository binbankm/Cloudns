import SwiftUI

struct SpeedSettingsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SpeedSettingsViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Auto Minify
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto Minify")
                                    .font(.body)
                                Text("Reduce the file size of source code on your website.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        Toggle("JavaScript", isOn: Binding(
                            get: { viewModel.minifyJS },
                            set: { val in
                                viewModel.minifyJS = val
                                Task { await viewModel.updateMinify(zoneId: zoneId, css: viewModel.minifyCSS, html: viewModel.minifyHTML, js: val) }
                            }
                        ))
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        Toggle("CSS", isOn: Binding(
                            get: { viewModel.minifyCSS },
                            set: { val in
                                viewModel.minifyCSS = val
                                Task { await viewModel.updateMinify(zoneId: zoneId, css: val, html: viewModel.minifyHTML, js: viewModel.minifyJS) }
                            }
                        ))
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        Toggle("HTML", isOn: Binding(
                            get: { viewModel.minifyHTML },
                            set: { val in
                                viewModel.minifyHTML = val
                                Task { await viewModel.updateMinify(zoneId: zoneId, css: viewModel.minifyCSS, html: val, js: viewModel.minifyJS) }
                            }
                        ))
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Advanced Optimizations
                    VStack(alignment: .leading, spacing: 0) {
                        
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
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
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
                                        .foregroundColor(.orange)
                                }
                                Text("Improve the paint time for pages which include JavaScript.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
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
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                }
                .padding()
                .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
                .disabled(!viewModel.hasFetchedData || viewModel.isLoading)
            }
            .refreshable {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
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
