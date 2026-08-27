import SwiftUI

// MARK: - AddAccessAppSheetView

struct AddAccessAppSheetView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: AccessAppsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var appName: String = ""
    @State private var appDomain: String = ""
    @State private var appType: String = "self_hosted"
    @State private var sessionDuration: String = "24h"
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    private let availableTypes: [(id: String, name: String, icon: String, color: Color)] = [
        ("self_hosted", "Self-Hosted Web App", "globe", .blue),
        ("ssh", "SSH Server", "terminal", .purple),
        ("vnc", "VNC Remote Desktop", "display", .orange),
        ("file_browser", "File Browser", "folder", .teal),
        ("warp", "WARP / Private Network", "shield.lefthalf.filled", .indigo)
    ]
    
    private let durationOptions: [(id: String, title: String)] = [
        ("1h", "1 Hour"),
        ("6h", "6 Hours"),
        ("12h", "12 Hours"),
        ("24h", "24 Hours (1 Day)"),
        ("7d", "7 Days"),
        ("30d", "30 Days")
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 1. Basic Information
                Section(header: Text("Application Details")) {
                    TextField("Application Name (e.g. Admin Portal)", text: $appName)
                        .keyboardType(.default)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Domain (e.g. portal.example.com)", text: $appDomain)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                // MARK: - 2. Application Type
                Section(header: Text("Application Type")) {
                    Picker("Type", selection: $appType) {
                        ForEach(availableTypes, id: \.id) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(type.color)
                                Text(type.name)
                            }
                            .tag(type.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: appType) { _ in
                        HapticManager.selection()
                    }
                }
                
                // MARK: - 3. Session Duration
                Section(header: Text("Session Duration"), footer: Text("How long a user stays authenticated before being prompted to log in again.")) {
                    Picker("Session Lifespan", selection: $sessionDuration) {
                        ForEach(durationOptions, id: \.id) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Access App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await saveApp() }
                    }
                    .disabled(!isValid || isSaving)
                    .overlay {
                        if isSaving { ProgressView() }
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
    
    private var isValid: Bool {
        !appName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !appDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    private func saveApp() async {
        let cleanName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDomain = appDomain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        
        isSaving = true
        errorMessage = nil
        HapticManager.impact(.medium)
        
        do {
            try await viewModel.createApp(
                name: cleanName,
                domain: cleanDomain,
                type: appType,
                sessionDuration: sessionDuration
            )
            HapticManager.notification(.success)
            CloudnsToastManager.shared.showSuccess("Access App Created", message: cleanName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
