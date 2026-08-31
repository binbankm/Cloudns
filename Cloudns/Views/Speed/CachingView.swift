import SwiftUI

struct CachingView: View {
    let zoneId: String
    let zoneName: String
    
    init(zoneId: String, zoneName: String = "") {
        self.zoneId = zoneId
        self.zoneName = zoneName
    }
    
    @StateObject private var viewModel = CachingViewModel()
    @State private var showingPurgeAlert = false
    @State private var purgeType = "url" // "url", "host", "prefix", "tag"
    @State private var purgeInputText = ""

    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.18), Color.teal.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 4)
                    
                    Text("Caching")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Manage edge cache levels, TTL expiration, and purge cache assets.")
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
            
            // MARK: - Custom Granular Purge
            Section(
                header: HStack {
                    Text("Custom Cache Purge")
                    Spacer()
                    if purgeType == "url" {
                        HIGBadge(.free, isCompact: true)
                    } else {
                        HIGBadge(.enterprise, isCompact: true)
                    }
                },
                footer: Text(purgeTypeDescription)
            ) {
                Picker("Purge By", selection: $purgeType) {
                    Text("URL").tag("url")
                    Text("Host (Ent)").tag("host")
                    Text("Prefix (Ent)").tag("prefix")
                    Text("Tag (Ent)").tag("tag")
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 2)
                .disabled(!viewModel.hasFetchedData)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField(purgePlaceholder, text: $purgeInputText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .disabled(!viewModel.hasFetchedData || viewModel.isPurging)
                        .onSubmit {
                            submitPurge()
                        }
                    
                    Button(action: {
                        submitPurge()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isPurging {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 4)
                            }
                            Text("Purge by \(purgeType.capitalized)")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(purgeInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(purgeInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPurging || !viewModel.hasFetchedData)
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - Cache Level & TTL
            Section(
                header: Text("Caching Configuration"),
                footer: Text("Determine how much of your website's static content you want Cloudflare to cache at the edge.")
            ) {
                // Cache Level
                HStack(spacing: 12) {
                    ListRowIcon(icon: "archivebox.fill", color: .blue, size: 28, cornerRadius: 6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Cache Level")
                            .font(.body)
                        Text(cacheLevelDescription(viewModel.cacheLevel))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Cache Level", selection: Binding(
                        get: { viewModel.cacheLevel },
                        set: { newValue in
                            guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                            HIGFeedback.selection()
                            Task { await viewModel.updateCacheLevel(zoneId: zoneId, level: newValue) }
                        }
                    )) {
                        Text("Basic").tag("basic")
                        Text("Simplified").tag("simplified")
                        Text("Standard").tag("aggressive")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Browser Cache TTL
                HStack(spacing: 12) {
                    ListRowIcon(icon: "clock.fill", color: .indigo, size: 28, cornerRadius: 6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Browser Cache TTL")
                            .font(.body)
                        Text("Length of time visitor's browser caches files.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Browser Cache TTL", selection: Binding(
                        get: { viewModel.browserCacheTTL },
                        set: { newValue in
                            guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                            HIGFeedback.selection()
                            Task { await viewModel.updateBrowserCacheTTL(zoneId: zoneId, ttl: newValue) }
                        }
                    )) {
                        Text("Respect Header").tag(0)
                        Text("30 mins").tag(1800)
                        Text("1 hour").tag(3600)
                        Text("4 hours").tag(14400)
                        Text("1 day").tag(86400)
                        Text("1 month").tag(2678400)
                        Text("1 year").tag(31536000)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Features
            Section(
                header: Text("Cache Features"),
                footer: Text("Development mode temporarily bypasses all caching to see origin changes instantly.")
            ) {
                // Always Online
                Toggle(isOn: Binding(
                    get: { viewModel.alwaysOnline },
                    set: { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HIGFeedback.selection()
                        Task { await viewModel.updateAlwaysOnline(zoneId: zoneId, isOn: newValue) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "wifi.circle.fill", color: .green, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Always Online™")
                                .font(.body)
                            Text("Serve cached pages when origin server is down.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Development Mode
                Toggle(isOn: Binding(
                    get: { viewModel.developmentMode },
                    set: { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HIGFeedback.selection()
                        Task { await viewModel.updateDevelopmentMode(zoneId: zoneId, isOn: newValue) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "hammer.fill", color: .orange, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Development Mode")
                                .font(.body)
                            Text("Temporarily bypass cache to test origin changes.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Danger Zone: Purge Everything
            Section(
                header: Text("Danger Zone").foregroundStyle(.red),
                footer: Text("Purging everything forces Cloudflare to re-fetch all assets from origin, which may increase server load.")
            ) {
                Button(action: {
                    HIGFeedback.impact(.medium)
                    showingPurgeAlert = true
                }) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "trash.fill", color: .red, size: 28, cornerRadius: 6)
                        Text("Purge Everything")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.red)
                        Spacer()
                        if viewModel.isPurging {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isPurging || !viewModel.hasFetchedData)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Caching Settings..."))
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData && !viewModel.isPurging && !viewModel.isLoading {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: { Task { await viewModel.fetchSettings(zoneId: zoneId) } }
                    )
                )
            }
        }
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .navigationTitle("Caching")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
        .confirmationDialog("Purge Everything?", isPresented: $showingPurgeAlert, titleVisibility: .visible) {
            Button("Purge All Cached Resources", role: .destructive) {
                HIGFeedback.warning()
                Task {
                    await viewModel.purgeCacheEverything(zoneId: zoneId)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to purge all cached resources? This may temporarily degrade your website's performance and increase load on your origin server.")
        }
    }
    
    private func submitPurge() {
        let clean = purgeInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty && !viewModel.isPurging else { return }
        let items = clean.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        HIGFeedback.impact(.medium)
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
    }
    
    private func cacheLevelDescription(_ level: String) -> LocalizedStringKey {
        switch level {
        case "basic": return "No Query String"
        case "simplified": return "Ignore Query String"
        case "aggressive": return "Standard Query String"
        default: return "Configuring..."
        }
    }
    
    private var purgeTypeDescription: LocalizedStringKey {
        switch purgeType {
        case "url": return "Purge exact full URLs (comma-separated)."
        case "host": return "Purge all cached resources on specific hostnames (Enterprise)."
        case "prefix": return "Purge all cached resources matching URL prefixes (Enterprise)."
        case "tag": return "Purge cached resources by Cache-Tag header values (Enterprise)."
        default: return ""
        }
    }
    
    private var purgePlaceholder: LocalizedStringKey {
        switch purgeType {
        case "url": return "https://example.com/asset.js, https://..."
        case "host": return "static.example.com, assets.example.com"
        case "prefix": return "https://example.com/static/, ..."
        case "tag": return "product-images, static-assets"
        default: return ""
        }
    }
}
