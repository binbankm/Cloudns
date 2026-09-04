import SwiftUI

// MARK: - AdvancedZoneSettingsView
// Apple HIG Compliant Advanced Zone Management (iOS 16.0+)

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
                VStack(spacing: 12) {
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
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                    
                    Text("Zone Management")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Advanced zone controls, bypass settings, and zone deletion for \(zoneName).")
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
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "pause.circle.fill", color: isPaused ? .orange : .gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pause Cloudflare on Site")
                                .font(.body.weight(.medium))
                            Text(isPaused ? "Proxy paused · Direct to origin" : "Proxy active · Protected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // MARK: - Danger Zone
            Section(
                header: Text("Danger Zone").foregroundStyle(.red),
                footer: Text("Removing this zone will permanently delete all its DNS records, firewall rules, and certificates from Cloudflare.")
            ) {
                Button(action: {
                    HIGFeedback.destructive()
                    showDeleteConfirmation = true
                }) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "trash.fill", color: .red)
                        Text("Remove Site from Cloudflare")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.red)
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        }
                    }
                }
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
    }
    
    // MARK: - API Operations
    
    private func updatePauseStatus(paused: Bool) async {
        isLoading = true
        do {
            _ = try await ZoneService.shared.pauseZone(zoneId: zoneId, paused: paused)
            await MainActor.run {
                isLoading = false
                NotificationCenter.default.post(name: .zoneUpdated, object: nil, userInfo: ["zoneId": zoneId])
                ToastManager.shared.showSuccess(paused ? "Cloudflare Paused" : "Cloudflare Resumed")
            }
        } catch {
            await MainActor.run {
                isLoading = false
                isPaused = !paused // Revert UI
                errorMessage = error.localizedDescription
                HIGFeedback.error()
            }
        }
    }
    
    private func deleteZone() async {
        isDeleting = true
        do {
            _ = try await ZoneService.shared.deleteZone(zoneId: zoneId)
            await MainActor.run {
                isDeleting = false
                HIGFeedback.success()
                NotificationCenter.default.post(name: .zoneDeleted, object: nil, userInfo: ["zoneId": zoneId])
                dismiss()
            }
        } catch {
            await MainActor.run {
                isDeleting = false
                errorMessage = error.localizedDescription
                HIGFeedback.error()
            }
        }
    }
}
