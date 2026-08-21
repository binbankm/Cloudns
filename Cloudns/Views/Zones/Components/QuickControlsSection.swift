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
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Under Attack Mode")
                        .font(.body)
                    Text("5-second challenge for all visitors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(isOn: $isUnderAttack) { }
                    .labelsHidden()
                    .disabled(updatingAttack)
                    .onChange(of: isUnderAttack) { val in
                        guard !updatingAttack else { return }
                        HapticManager.impact(.light)
                        Task { await setUnderAttack(val) }
                    }
            }
            .padding(.vertical, 2)

            // Development Mode
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.body)
                    .foregroundStyle(isDevMode ? .white : .orange)
                    .frame(width: 32, height: 32)
                    .background(isDevMode ? Color.orange : Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Development Mode")
                        .font(.body)
                    Text("Bypass cache for 3 hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(isOn: $isDevMode) { }
                    .labelsHidden()
                    .disabled(updatingDev)
                    .onChange(of: isDevMode) { val in
                        guard !updatingDev else { return }
                        HapticManager.impact(.light)
                        Task { await setDevMode(val) }
                    }
            }
            .padding(.vertical, 2)

            // Pause Cloudflare
            HStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.body)
                    .foregroundStyle(isPaused ? .white : .secondary)
                    .frame(width: 32, height: 32)
                    .background(isPaused ? Color.secondary : Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Pause Cloudflare")
                        .font(.body)
                    Text("Route traffic directly to origin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle(isOn: $isPaused) { }
                    .labelsHidden()
                    .disabled(updatingPause)
                    .onChange(of: isPaused) { val in
                        guard !updatingPause else { return }
                        HapticManager.impact(.light)
                        Task { await setPaused(val) }
                    }
            }
            .padding(.vertical, 2)
        }
        .task { await fetchInitialStates() }
        .onReceive(NotificationCenter.default.publisher(for: .zoneUpdated)) { _ in
            Task {
                guard !updatingPause else { return }
                if let zd = try? await ZoneService.shared.getZoneDetails(zoneId: zoneId) {
                    await MainActor.run {
                        self.isPaused = zd.paused
                    }
                }
            }
        }
    }

    // MARK: - Fetch

    private func fetchInitialStates() async {
        async let fetchSec: () = {
            if let sec = try? await SecuritySettingsService.shared.getSecuritySettings(zoneId: zoneId) {
                await MainActor.run {
                    if !updatingAttack {
                        self.isUnderAttack = (sec.level == "under_attack")
                    }
                }
            }
        }()
        
        async let fetchCache: () = {
            if let cache = try? await SpeedAndNetworkService.shared.getCachingSettings(zoneId: zoneId) {
                await MainActor.run {
                    if !updatingDev {
                        self.isDevMode = cache.devMode
                    }
                }
            }
        }()
        
        async let fetchZone: () = {
            if let zd = try? await ZoneService.shared.getZoneDetails(zoneId: zoneId) {
                await MainActor.run {
                    if !updatingPause {
                        self.isPaused = zd.paused
                    }
                }
            }
        }()
        
        _ = await (fetchSec, fetchCache, fetchZone)
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
            ToastManager.shared.showSuccess("Under Attack Mode", message: on ? "Enabled (5s challenge active)" : "Disabled")
        } catch {
            isUnderAttack = !on
            ToastManager.shared.showError("Failed to update Under Attack Mode")
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
            ToastManager.shared.showSuccess("Development Mode", message: on ? "Enabled (Cache bypassed for 3h)" : "Disabled")
        } catch {
            isDevMode = !on
            ToastManager.shared.showError("Failed to update Development Mode")
        }
        updatingDev = false
    }

    private func setPaused(_ on: Bool) async {
        updatingPause = true
        do {
            try await ZoneService.shared.updateZoneStatus(zoneId: zoneId, paused: on)
            NotificationCenter.default.post(name: .zoneUpdated, object: nil)
            ToastManager.shared.showSuccess("Zone Status", message: on ? "Domain paused on Cloudflare" : "Domain active on Cloudflare")
        } catch {
            isPaused = !on
            ToastManager.shared.showError("Failed to update Zone Status")
        }
        updatingPause = false
    }
}
