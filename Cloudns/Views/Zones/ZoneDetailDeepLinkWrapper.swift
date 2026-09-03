import SwiftUI

// MARK: - ZoneDetailDeepLinkWrapper
// Apple HIG Compliant Deep Link Loader for Domains

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
                HIGContentState(.loading(message: "Loading Domain…"))
            } else {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage ?? "Unable to load domain"),
                        retryAction: {
                            Task { await loadZone() }
                        }
                    )
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    onDismiss()
                }
                .font(HIGTypography.body.weight(.semibold))
                .foregroundStyle(Color.higAccent)
                .higTouchTarget()
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
        
        // 2. Fetch from Cloudflare API
        do {
            let fetched = try await ZoneService.shared.getZoneDetails(zoneId: zoneId)
            self.loadedZone = fetched
        } catch {
            // 3. If remote fails, fallback to widget snapshot cache
            let snap = WidgetDataStore.shared.loadZoneSnapshot()
            if snap.id == zoneId {
                self.loadedZone = Zone(
                    id: snap.id,
                    name: snap.name,
                    status: snap.status,
                    paused: !snap.isProxied,
                    plan: ZonePlan(name: snap.plan)
                )
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
        self.isLoading = false
    }
}
