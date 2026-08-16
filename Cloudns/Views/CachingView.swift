import SwiftUI

struct CachingView: View {
    let zoneId: String
    
    @StateObject private var viewModel = CachingViewModel()
    @State private var showingPurgeAlert = false
    @State private var purgeType = "url" // "url", "host", "prefix", "tag"
    @State private var purgeInputText = ""

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
            
            // Custom Granular Purge
            Section(
                header: Text("Custom Cache Purge"),
                footer: Text(purgeTypeDescription)
            ) {
                Picker("Purge By", selection: $purgeType) {
                    Text("URL").tag("url")
                    Text("Host").tag("host")
                    Text("Prefix").tag("prefix")
                    Text("Tag").tag("tag")
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 2)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField(purgePlaceholder, text: $purgeInputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: {
                        let clean = purgeInputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !clean.isEmpty else { return }
                        let items = clean.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        
                        Task {
                            if purgeType == "url" {
                                await viewModel.purgeCacheByURLs(zoneId: zoneId, urls: items)
                            } else if purgeType == "host" {
                                await viewModel.purgeCacheByHosts(zoneId: zoneId, hosts: items)
                            } else if purgeType == "prefix" {
                                await viewModel.purgeCacheByPrefixes(zoneId: zoneId, prefixes: items)
                            } else if purgeType == "tag" {
                                await viewModel.purgeCacheByTags(zoneId: zoneId, tags: items)
                            }
                            purgeInputText = ""
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isPurging {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Text("Purge by \(purgeType.capitalized)")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(purgeInputText.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(purgeInputText.isEmpty || viewModel.isPurging)
                }
                .padding(.vertical, 4)
            }
            
            // Danger Zone: Purge Cache
            Section(header: Text("Danger Zone")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                        Text("Purge Everything")
                            .font(.body)
                            .foregroundStyle(.red)
                    }
                    
                    Text("Purge everything from Cloudflare's cache. This will force Cloudflare to fetch a fresh version of your site from your origin server.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
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
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isPurging || !viewModel.hasFetchedData)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)
            
            // Cache Level
            Section(header: Text("Cache Level")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Determine how much of your website's static content you want Cloudflare to cache.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
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
            }
            
            // Browser Cache TTL
            Section(header: Text("Browser Cache TTL")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Determine the length of time Cloudflare instructs a visitor's browser to cache files.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
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
            }
            
            // Always Online
            Section(header: Text("Always Online™")) {
                Toggle(isOn: $viewModel.alwaysOnline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("If your server goes down, Cloudflare will serve your website's static pages from our cache.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: viewModel.alwaysOnline) { newValue in
                    Task {
                        await viewModel.updateAlwaysOnline(zoneId: zoneId, isOn: newValue)
                    }
                }
            }
            
            // Development Mode
            Section(header: Text("Development Mode")) {
                Toggle(isOn: $viewModel.developmentMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temporarily bypass our cache. Allows you to see changes to your origin server in realtime.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: viewModel.developmentMode) { newValue in
                    Task {
                        await viewModel.updateDevelopmentMode(zoneId: zoneId, isOn: newValue)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
        .disabled(!viewModel.hasFetchedData)
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
    
    private var purgeTypeDescription: String {
        switch purgeType {
        case "url": return "Purge exact full URLs (comma-separated)."
        case "host": return "Purge all cached resources on specific hostnames (Enterprise)."
        case "prefix": return "Purge all cached resources matching URL prefixes (Enterprise)."
        case "tag": return "Purge cached resources by Cache-Tag header values (Enterprise)."
        default: return ""
        }
    }
    
    private var purgePlaceholder: String {
        switch purgeType {
        case "url": return "https://example.com/asset.js, https://..."
        case "host": return "static.example.com, assets.example.com"
        case "prefix": return "https://example.com/static/, ..."
        case "tag": return "product-images, static-assets"
        default: return ""
        }
    }
}
