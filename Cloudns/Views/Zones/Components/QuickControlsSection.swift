import SwiftUI

// MARK: - QuickControlsSection

struct QuickControlsSection: View {
    let zoneId: String

    @State private var isUnderAttack: Bool = false
    @State private var isDevMode: Bool = false
    @State private var isPaused: Bool
    @State private var isLoading: Bool = true
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

                if updatingAttack || isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Toggle(isOn: $isUnderAttack) { }
                        .labelsHidden()
                        .onChange(of: isUnderAttack) { val in
                            guard hasFetchedData && !isLoading && !updatingAttack else { return }
                            HapticManager.impact(.light)
                            Task { await setUnderAttack(val) }
                        }
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

                if updatingDev || isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Toggle(isOn: $isDevMode) { }
                        .labelsHidden()
                        .onChange(of: isDevMode) { val in
                            guard hasFetchedData && !isLoading && !updatingDev else { return }
                            HapticManager.impact(.light)
                            Task { await setDevMode(val) }
                        }
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

                if updatingPause {
                    ProgressView().controlSize(.small)
                } else {
                    Toggle(isOn: $isPaused) { }
                        .labelsHidden()
                        .onChange(of: isPaused) { val in
                            guard hasFetchedData && !isLoading && !updatingPause else { return }
                            HapticManager.impact(.light)
                            Task { await setPaused(val) }
                        }
                }
            }
            .padding(.vertical, 2)
        }
        .task { await fetchInitialStates() }
    }

    // MARK: - Fetch

    private func fetchInitialStates() async {
        if hasFetchedData { return }
        isLoading = true
        do {
            async let secSettings = SecuritySettingsService.shared.getSecuritySettings(zoneId: zoneId)
            async let cacheSettings = SpeedAndNetworkService.shared.getCachingSettings(zoneId: zoneId)
            let (sec, cache) = try await (secSettings, cacheSettings)
            isUnderAttack = (sec.level == "under_attack")
            isDevMode = cache.devMode
        } catch {
            // Silently fail — toggles stay at defaults
        }
        isLoading = false
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
