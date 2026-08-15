import SwiftUI

struct CachingView: View {
    let zoneId: String
    
    @StateObject private var viewModel = CachingViewModel()
    @State private var showingPurgeAlert = false
    @State private var purgeUrlText = ""
    
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
                    
                    if let successMessage = viewModel.purgeSuccessMessage {
                        Text(successMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    if let purgeError = viewModel.purgeErrorMessage {
                        Text(purgeError)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Purge By URL
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text("Purge by URL")
                                .font(.body)
                        }
                        
                        Text("Clear cached files by their exact URLs. This allows you to selectively refresh specific resources.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("https://example.com/style.css", text: $purgeUrlText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            Button(action: {
                                guard !purgeUrlText.isEmpty else { return }
                                let urls = [purgeUrlText.trimmingCharacters(in: .whitespacesAndNewlines)]
                                Task {
                                    await viewModel.purgeCacheByURLs(zoneId: zoneId, urls: urls)
                                    purgeUrlText = ""
                                }
                            }) {
                                Text("Purge")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(purgeUrlText.isEmpty ? Color.gray : Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(purgeUrlText.isEmpty || viewModel.isPurging)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Danger Zone: Purge Cache
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Purge Everything")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                        
                        Text("Purge everything from Cloudflare's cache. This will force Cloudflare to fetch a fresh version of your site from your origin server.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingPurgeAlert = true
                        }) {
                            HStack {
                                Spacer()
                                if viewModel.isPurging {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Purge Everything")
                                        .fontWeight(.bold)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isPurging || !viewModel.hasFetchedData)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    
                    // Settings Section
                    VStack(spacing: 0) {
                        
                        // Cache Level
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cache Level")
                                    .font(.body)
                                Text("Determine how much of your website's static content you want Cloudflare to cache.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Picker("Cache Level", selection: $viewModel.cacheLevel) {
                                Text("No Query String").tag("basic")
                                Text("Ignore Query String").tag("simplified")
                                Text("Standard").tag("aggressive")
                            }
                            .pickerStyle(.menu)
                            .onChange(of: viewModel.cacheLevel) { newValue in
                                Task {
                                    await viewModel.updateCacheLevel(zoneId: zoneId, level: newValue)
                                }
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Browser Cache TTL
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Browser Cache TTL")
                                    .font(.body)
                                Text("Determine the length of time Cloudflare instructs a visitor's browser to cache files.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Picker("TTL", selection: $viewModel.browserCacheTTL) {
                                Text("Respect Existing").tag(0)
                                Text("30 minutes").tag(1800)
                                Text("1 hour").tag(3600)
                                Text("4 hours").tag(14400)
                                Text("1 day").tag(86400)
                                Text("1 month").tag(2678400)
                                Text("1 year").tag(31536000)
                            }
                            .pickerStyle(.menu)
                            .onChange(of: viewModel.browserCacheTTL) { newValue in
                                Task {
                                    await viewModel.updateBrowserCacheTTL(zoneId: zoneId, ttl: newValue)
                                }
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Always Online
                        Toggle(isOn: $viewModel.alwaysOnline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Always Online™")
                                    .font(.body)
                                Text("If your server goes down, Cloudflare will serve your website's static pages from our cache.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.alwaysOnline) { newValue in
                            Task {
                                await viewModel.updateAlwaysOnline(zoneId: zoneId, isOn: newValue)
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Development Mode
                        Toggle(isOn: $viewModel.developmentMode) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Development Mode")
                                    .font(.body)
                                Text("Temporarily bypass our cache. Allows you to see changes to your origin server in realtime.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.developmentMode) { newValue in
                            Task {
                                await viewModel.updateDevelopmentMode(zoneId: zoneId, isOn: newValue)
                            }
                        }
                        .padding()
                        
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    
                }
                .padding()
                .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
                .disabled(!viewModel.hasFetchedData)
            }
            .refreshable {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
        .navigationTitle("Caching")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
        .alert("Purge Everything?", isPresented: $showingPurgeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Purge", role: .destructive) {
                Task {
                    await viewModel.purgeCacheEverything(zoneId: zoneId)
                }
            }
        } message: {
            Text("Are you sure you want to purge all cached resources? This may temporarily degrade your website's performance and increase load on your origin server.")
        }
    }
}
