import SwiftUI

// MARK: - AdvancedZoneSettingsView
// Apple HIG Compliant Advanced Zone Management

struct AdvancedZoneSettingsView: View {
    let zoneId: String
    let zoneName: String
    
    @State private var isPaused: Bool
    
    init(zoneId: String, zoneName: String, initialPaused: Bool) {
        self.zoneId = zoneId
        self.zoneName = zoneName
        self._isPaused = State(initialValue: initialPaused)
    }
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: HIGTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.18), Color.secondary.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "gearshape.2.fill")
                            .font(HIGTypography.title.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, HIGTokens.Spacing.xs)
                    
                    Text("Zone Management")
                        .font(HIGTypography.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Advanced zone controls, bypass settings, and zone deletion for \(zoneName).")
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HIGTokens.Spacing.lg)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HIGTokens.Spacing.sm)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // MARK: - Pause Cloudflare
            Section(
                header: Text("Pause Cloudflare"),
                footer: Text("Directly route traffic to your origin server, bypassing Cloudflare's security and caching proxy.")
            ) {
                Toggle(isOn: Binding(
                    get: { isPaused },
                    set: { newValue in
                        isPaused = newValue
                        if newValue {
                            HIGFeedback.warning()
                        } else {
                            HIGFeedback.selection()
                        }
                        Task {
                            await updatePauseStatus(paused: newValue)
                        }
                    }
                )) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "pause.circle.fill", color: isPaused ? HIGColors.warning : .gray)
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text("Pause Cloudflare on Site")
                                .font(HIGTypography.body.weight(.medium))
                            Text(isPaused ? "Proxy paused · Direct to origin" : "Proxy active · Protected")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // MARK: - Danger Zone
            Section(
                header: Text("Danger Zone").foregroundStyle(HIGColors.error),
                footer: Text("Removing this zone will permanently delete all its DNS records, firewall rules, and certificates from Cloudflare.")
            ) {
                Button(action: {
                    HIGFeedback.impact(.medium)
                    showDeleteConfirmation = true
                }) {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "trash.fill", color: HIGColors.error)
                        Text("Remove Site from Cloudflare")
                            .font(HIGTypography.body.weight(.semibold))
                            .foregroundStyle(HIGColors.error)
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.higPressable)
                .higTouchTarget()
                .disabled(isDeleting)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Advanced")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Remove Site from Cloudflare", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Remove \(zoneName)", role: .destructive) {
                Task {
                    await deleteZone()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(zoneName) from Cloudflare? This action is permanent and cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "Unknown error")
        })
        .task {
            if let zd = try? await ZoneService.shared.getZoneDetails(zoneId: zoneId) {
                self.isPaused = zd.paused
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoneUpdated)) { _ in
            Task {
                if let zd = try? await ZoneService.shared.getZoneDetails(zoneId: zoneId) {
                    await MainActor.run {
                        self.isPaused = zd.paused
                    }
                }
            }
        }
        .higToast()
    }
    
    private func updatePauseStatus(paused: Bool) async {
        isLoading = true
        errorMessage = nil
        do {
            try await ZoneService.shared.pauseZone(zoneId: zoneId, paused: paused)
            ToastManager.shared.showSuccess(paused ? "Cloudflare Paused" : "Cloudflare Resumed", icon: paused ? "pause.circle.fill" : "play.circle.fill")
        } catch {
            errorMessage = error.localizedDescription
            isPaused = !paused
            ToastManager.shared.showError("Failed to update status")
            HIGFeedback.error()
        }
        isLoading = false
    }
    
    private func deleteZone() async {
        isDeleting = true
        errorMessage = nil
        do {
            _ = try await ZoneService.shared.deleteZone(zoneId: zoneId)
            ToastManager.shared.showSuccess("Zone Deleted", icon: "trash.fill")
            HIGFeedback.success()
            NotificationCenter.default.post(name: .zoneDeleted, object: nil, userInfo: ["zoneId": zoneId])
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed to delete zone")
            HIGFeedback.error()
        }
        isDeleting = false
    }
}
