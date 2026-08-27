import SwiftUI

// MARK: - QuickControlsSection

struct QuickControlsSection: View {
    let zoneId: String

    @State private var isUnderAttack: Bool = false
    @State private var isDevMode: Bool = false
    @State private var isPaused: Bool
    @State private var hasFetchedData: Bool = false

    @State private var updatingAttack: Bool = false
    @State private var updatingDev: Bool = false
    @State private var updatingPause: Bool = false

    init(zoneId: String, initialPaused: Bool) {
        self.zoneId = zoneId
        self._isPaused = State(initialValue: initialPaused)
    }

    var body: some View {
        Section(header: Text("Quick Controls")) {
            // Under Attack Mode
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.body)
                    .foregroundStyle(isUnderAttack ? .white : .red)
                    .frame(width: 32, height: 32)
                    .background(isUnderAttack ? Color.red : Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Under Attack Mode")
                        .font(.body)
                    Text("5-second challenge for all visitors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { isUnderAttack },
                    set: { val in
                        guard !updatingAttack else { return }
                        isUnderAttack = val
                        HapticManager.impact(.light)
                        Task { await setUnderAttack(val) }
                    }
                )) { }
                    .labelsHidden()
                    .disabled(updatingAttack)
            }
            .padding(.vertical, 2)

            // Development Mode
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.body)
                    .foregroundStyle(isDevMode ? .white : .orange)
                    .frame(width: 32, height: 32)
                    .background(isDevMode ? Color.orange : Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Development Mode")
                        .font(.body)
                    Text("Bypass cache, lasts 3 hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { isDevMode },
                    set: { val in
                        guard !updatingDev else { return }
                        isDevMode = val
                        HapticManager.impact(.light)
                        Task { await setDevMode(val) }
                    }
                )) { }
                    .labelsHidden()
                    .disabled(updatingDev)
            }
            .padding(.vertical, 2)

            // Pause Cloudflare on Site
            HStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.body)
                    .foregroundStyle(isPaused ? .white : .gray)
                    .frame(width: 32, height: 32)
                    .background(isPaused ? Color.gray : Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Pause Cloudflare")
                        .font(.body)
                    Text("Route traffic directly to origin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { isPaused },
                    set: { val in
                        guard !updatingPause else { return }
                        isPaused = val
                        HapticManager.impact(.light)
                        Task { await setPaused(val) }
                    }
                )) { }
                    .labelsHidden()
                    .disabled(updatingPause)
            }
            .padding(.vertical, 2)
        }
        .task { await fetchInitialStates() }
        .onReceive(NotificationCenter.default.publisher(for: .zoneUpdated)) { _ in
            Task {
                guard !updatingPause else { return }
                if let zd = try? await ZoneService.shared.getZoneDetails(zoneId: zoneId) {
                    self.isPaused = zd.paused
                }
            }
        }
    }

    // MARK: - Fetch

    private func fetchInitialStates() async {
        async let fetchSec = try? SecuritySettingsService.shared.getSecuritySettings(zoneId: zoneId)
        async let fetchCache = try? SpeedAndNetworkService.shared.getCachingSettings(zoneId: zoneId)
        async let fetchZone = try? ZoneService.shared.getZoneDetails(zoneId: zoneId)
        
        let (secResult, cacheResult, zdResult) = await (fetchSec, fetchCache, fetchZone)
        
        if let sec = secResult, !updatingAttack {
            self.isUnderAttack = (sec.level == "under_attack")
        }
        if let cache = cacheResult, !updatingDev {
            self.isDevMode = cache.devMode
        }
        if let zd = zdResult, !updatingPause {
            self.isPaused = zd.paused
        }
        hasFetchedData = true
    }

    // MARK: - Mutations

    private func setUnderAttack(_ on: Bool) async {
        updatingAttack = true
        do {
            try await SecuritySettingsService.shared.updateSecurityLevel(
                zoneId: zoneId,
                level: on ? "under_attack" : "medium"
            )
            CloudnsToastManager.shared.showSuccess("Under Attack Mode", message: on ? "Enabled (5s challenge active)" : "Disabled")
        } catch {
            isUnderAttack = !on
            CloudnsToastManager.shared.showError("Failed to update Under Attack Mode")
        }
        updatingAttack = false
    }

    private func setDevMode(_ on: Bool) async {
        updatingDev = true
        do {
            try await SpeedAndNetworkService.shared.updateDevelopmentMode(
                zoneId: zoneId,
                isOn: on
            )
            NotificationCenter.default.post(name: .zoneUpdated, object: nil)
            CloudnsToastManager.shared.showSuccess("Development Mode", message: on ? "Enabled (Cache bypassed for 3h)" : "Disabled")
        } catch {
            isDevMode = !on
            CloudnsToastManager.shared.showError("Failed to update Development Mode")
        }
        updatingDev = false
    }

    private func setPaused(_ on: Bool) async {
        updatingPause = true
        do {
            try await ZoneService.shared.updateZoneStatus(zoneId: zoneId, paused: on)
            NotificationCenter.default.post(name: .zoneUpdated, object: nil)
            CloudnsToastManager.shared.showSuccess("Zone Status", message: on ? "Domain paused on Cloudflare" : "Domain active on Cloudflare")
        } catch {
            isPaused = !on
            CloudnsToastManager.shared.showError("Failed to update Zone Status")
        }
        updatingPause = false
    }
}
