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
    
    // Environment for dismissing to root
    @Environment(\.presentationMode) var presentationMode
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
                    Task {
                        await updatePauseStatus(paused: newValue)
                    }
                }
            }
            
            Section(
                header: Text("Danger Zone").foregroundColor(.red),
                footer: Text("Removing this site will immediately delete all its configuration and data from Cloudflare. This action cannot be undone.")
            ) {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        } else {
                            Text("Remove Site from Cloudflare")
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(isDeleting)
            }
        }
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove Site", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    await deleteZone()
                }
            }
        } message: {
            Text("Are you sure you want to remove \(zoneName) from Cloudflare? This action is permanent and cannot be undone.")
        }
        .alert(isPresented: .constant(errorMessage != nil)) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    errorMessage = nil
                }
            )
        }
    }
    
    private func updatePauseStatus(paused: Bool) async {
        do {
            try await CloudflareAPIClient.shared.updateZoneStatus(zoneId: zoneId, paused: paused)
            NotificationCenter.default.post(name: NSNotification.Name("ZoneUpdated"), object: nil)
        } catch {
            self.errorMessage = error.localizedDescription
            // Revert state
            self.isPaused = !paused
        }
    }
    
    private func deleteZone() async {
        isDeleting = true
        do {
            try await CloudflareAPIClient.shared.deleteZone(zoneId: zoneId)
            isDeleting = false
            // After deleting, we need to return to the root Dashboard view.
            NotificationCenter.default.post(name: NSNotification.Name("ZoneDeleted"), object: nil)
            dismiss()
        } catch {
            isDeleting = false
            self.errorMessage = error.localizedDescription
        }
    }
}
