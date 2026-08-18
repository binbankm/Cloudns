import SwiftUI

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
        Form {
            Section(
                header: Text("Pause Cloudflare"),
                footer: Text("Pause Cloudflare on Site. This will route traffic directly to your origin server, bypassing Cloudflare's security and caching.")
            ) {
                Toggle(isOn: $isPaused) {
                    Text("Pause Cloudflare")
                }
                .onChange(of: isPaused) { newValue in
                    if newValue {
                        HapticManager.notification(.warning)
                    } else {
                        HapticManager.impact(.light)
                    }
                    Task {
                        await updatePauseStatus(paused: newValue)
                    }
                }
            }
            
            Section(
                header: Text("Danger Zone").foregroundStyle(.red),
                footer: Text("Removing this site will immediately delete all its configuration and data from Cloudflare. This action cannot be undone.")
            ) {
                Button(action: {
                    HapticManager.impact(.medium)
                    showDeleteConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        } else {
                            Text("Remove Site from Cloudflare")
                                .foregroundStyle(.red)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(isDeleting)
            }
        }
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Advanced Settings")
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
    
    private func updatePauseStatus(paused: Bool) async {
        do {
            try await ZoneService.shared.updateZoneStatus(zoneId: zoneId, paused: paused)
            NotificationCenter.default.post(name: .zoneUpdated, object: nil)
            ToastManager.shared.showSuccess(paused ? "Site Paused" : "Site Resumed")
        } catch {
            self.errorMessage = error.localizedDescription
            self.isPaused = !paused
        }
    }
    
    private func deleteZone() async {
        isDeleting = true
        do {
            _ = try await ZoneService.shared.deleteZone(zoneId: zoneId)
            isDeleting = false
            NotificationCenter.default.post(name: .zoneDeleted, object: nil)
            dismiss()
        } catch {
            isDeleting = false
            self.errorMessage = error.localizedDescription
        }
    }
}
