import SwiftUI

// MARK: - ZoneDetailDeepLinkWrapper
// Apple HIG Compliant Deep Link Loader for Domains (iOS 16.0+)

struct ZoneDetailDeepLinkWrapper: View {
    let zoneId: String
    let onDismiss: () -> Void
    
    @State private var loadedZone: Zone?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if let zone = loadedZone {
                ZoneDetailView(zone: zone)
            } else if isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading Domain…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(.largeTitle).weight(.light))
                        .foregroundStyle(.orange)
                    Text("Unable to Load")
                        .font(.headline)
                    Text(errorMessage ?? String(localized: "Unable to load domain"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await loadZone() }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    onDismiss()
                }
                .font(.body.weight(.semibold))
            }
        }
        .task {
            await loadZone()
        }
    }
    
    private func loadZone() async {
        guard !zoneId.isEmpty, zoneId != "placeholder-zone-id", zoneId != "placeholder" else {
            onDismiss()
            return
        }
        
        isLoading = true
        // 1. Check local SWR cache first
        let cacheKey = SWRCacheStore.accountScopedKey("cloudflare_zones_list")
        if let cachedZones = await SWRCacheStore.shared.get(forKey: cacheKey, as: [Zone].self),
           let match = cachedZones.first(where: { $0.id == zoneId }) {
            self.loadedZone = match
            self.isLoading = false
            return
        }
        
        // 2. Fetch fresh from network
        do {
            let fetched = try await ZoneService.shared.getZoneDetails(zoneId: zoneId)
            self.loadedZone = fetched
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
