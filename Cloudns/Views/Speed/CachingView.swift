import SwiftUI

// MARK: - CachingView
// Apple HIG Compliant Cloudflare Edge Caching, TTL Configuration & Granular Purge

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
                VStack(spacing: HIGTokens.Spacing.md) {
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
                            .font(HIGTypography.title2.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, HIGTokens.Spacing.xs)
                    
                    Text("Caching")
                        .font(HIGTypography.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Manage edge cache levels, TTL expiration, and purge cache assets.")
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
                .padding(.vertical, HIGTokens.Spacing.xxs)
                .disabled(!viewModel.hasFetchedData)
                
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
                    TextField(purgePlaceholder, text: $purgeInputText)
                        .font(HIGTypography.body.monospaced())
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
                                    .padding(.trailing, HIGTokens.Spacing.xs)
                            }
                            Text("Purge by \(purgeType.capitalized)")
                                .font(HIGTypography.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, HIGTokens.Spacing.sm)
                        .background(purgeInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.higAccent)
                        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.higPressable)
                    .disabled(purgeInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPurging || !viewModel.hasFetchedData)
                    .higTouchTarget(44)
                }
                .padding(.vertical, HIGTokens.Spacing.xs)
            }
            
            // MARK: - Cache Level & TTL
            Section(
                header: Text("Caching Configuration"),
                footer: Text("Determine how much of your website's static content you want Cloudflare to cache at the edge.")
            ) {
                // Cache Level
                HStack(spacing: HIGTokens.Spacing.md) {
                    ListRowIcon(icon: "archivebox.fill", color: .blue)
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        Text("Cache Level")
                            .font(HIGTypography.body)
                        Text(cacheLevelDescription(viewModel.cacheLevel))
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Cache Level", selection: Binding(
                        get: { viewModel.cacheLevel },
                        set: { newValue in
                            guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                            HIGFeedback.selection()
                            Task {
                                await viewModel.updateCacheLevel(zoneId: zoneId, level: newValue)
                                ToastManager.shared.showSuccess("Cache Level Updated", icon: "archivebox.fill")
                            }
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
                HStack(spacing: HIGTokens.Spacing.md) {
                    ListRowIcon(icon: "clock.fill", color: .indigo)
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        Text("Browser Cache TTL")
                            .font(HIGTypography.body)
                        Text("Length of time visitor's browser caches files.")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Browser Cache TTL", selection: Binding(
                        get: { viewModel.browserCacheTTL },
                        set: { newValue in
                            guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                            HIGFeedback.selection()
                            Task {
                                await viewModel.updateBrowserCacheTTL(zoneId: zoneId, ttl: newValue)
                                ToastManager.shared.showSuccess("Browser TTL Updated", icon: "clock.fill")
                            }
                        }
                    )) {
                        Text("Respect Existing Headers").tag(0)
                        Text("30 Minutes").tag(1800)
                        Text("1 Hour").tag(3600)
                        Text("4 Hours").tag(14400)
                        Text("8 Hours").tag(28800)
                        Text("1 Day").tag(86400)
                        Text("8 Days").tag(691200)
                        Text("1 Month").tag(2592000)
                        Text("1 Year").tag(31536000)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Always Online
                Toggle(isOn: Binding(
                    get: { viewModel.alwaysOnline },
                    set: { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HIGFeedback.selection()
                        Task {
                            await viewModel.updateAlwaysOnline(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess(newValue ? "Always Online Enabled" : "Always Online Disabled", icon: "cloud.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "cloud.fill", color: .teal)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Always Online")
                                .font(HIGTypography.body)
                            Text("Serve cached pages to visitors if your origin goes down.")
                                .font(HIGTypography.caption)
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
                        Task {
                            await viewModel.updateDevelopmentMode(zoneId: zoneId, isOn: newValue)
                            ToastManager.shared.showSuccess(newValue ? "Dev Mode Enabled (Bypassing Cache)" : "Dev Mode Disabled", icon: "hammer.fill")
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "hammer.fill", color: .orange)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            HStack(spacing: HIGTokens.Spacing.xs) {
                                Text("Development Mode")
                                    .font(HIGTypography.body)
                                if viewModel.developmentMode {
                                    HIGBadge(.warning("3 Hours"), isCompact: true)
                                }
                            }
                            Text("Temporarily bypass edge cache to see immediate changes.")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Quick Action (Purge Everything)
            Section(
                header: Text("Purge Cache"),
                footer: Text("Purging everything removes all cached resources from Cloudflare's global edge network immediately.")
            ) {
                Button(role: .destructive) {
                    HIGFeedback.warning()
                    showingPurgeAlert = true
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isPurging && purgeInputText.isEmpty {
                            ProgressView()
                                .tint(HIGColors.error)
                                .padding(.trailing, HIGTokens.Spacing.xs)
                        }
                        Text("Purge Everything")
                            .font(HIGTypography.body.weight(.medium))
                        Spacer()
                    }
                }
                .disabled(viewModel.isPurging || !viewModel.hasFetchedData)
                .higTouchTarget(44)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Caching")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Caching Settings…"))
            }
        }
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .confirmationDialog(
            "Purge Everything?",
            isPresented: $showingPurgeAlert,
            titleVisibility: .visible
        ) {
            Button("Purge Everything", role: .destructive) {
                Task {
                    await viewModel.purgeCacheEverything(zoneId: zoneId)
                    ToastManager.shared.showSuccess("Cache Purged Completely", icon: "trash.fill")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Purging all cached resources can temporarily degrade origin server performance while assets re-cache.")
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
    }
    
    private var purgePlaceholder: String {
        switch purgeType {
        case "url": return "https://\(zoneName.isEmpty ? "example.com" : zoneName)/style.css"
        case "host": return "assets.\(zoneName.isEmpty ? "example.com" : zoneName)"
        case "prefix": return "https://\(zoneName.isEmpty ? "example.com" : zoneName)/images/"
        case "tag": return "static-v1"
        default: return "Input value"
        }
    }
    
    private var purgeTypeDescription: String {
        switch purgeType {
        case "url": return "Purge single or multiple exact URL files on Free, Pro, Business & Enterprise plans."
        case "host": return "Purge all cached resources for a specific hostname (Enterprise only)."
        case "prefix": return "Purge all files within a specific path prefix (Enterprise only)."
        case "tag": return "Purge all cached assets with a given Cache-Tag header (Enterprise only)."
        default: return ""
        }
    }
    
    private func submitPurge() {
        let text = purgeInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        HIGFeedback.impact(.medium)
        Task {
            switch purgeType {
            case "url":
                let urls = text.components(separatedBy: CharacterSet(charactersIn: ",\n ")).filter { !$0.isEmpty }
                await viewModel.purgeCacheByURLs(zoneId: zoneId, urls: urls)
            case "host":
                await viewModel.purgeCacheByHosts(zoneId: zoneId, hosts: [text])
            case "prefix":
                await viewModel.purgeCacheByPrefixes(zoneId: zoneId, prefixes: [text])
            case "tag":
                await viewModel.purgeCacheByTags(zoneId: zoneId, tags: [text])
            default:
                break
            }
            purgeInputText = ""
            ToastManager.shared.showSuccess("Purge Request Sent", icon: "arrow.counterclockwise.circle.fill")
        }
    }
    
    private func cacheLevelDescription(_ level: String) -> String {
        switch level {
        case "basic": return "Ignores query string and serves cached static file."
        case "simplified": return "Serves same file to all visitors regardless of query string."
        case "aggressive": return "Delivers different asset for each unique query string."
        default: return "Configuring…"
        }
    }
}
