import SwiftUI

// MARK: - CreateTurnstileWidgetSheetView

struct CreateTurnstileWidgetSheetView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: TurnstileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var widgetName = ""
    @State private var domainsText = "example.com"
    @State private var selectedMode = "managed"
    @State private var isSubmitting = false
    
    private let modes = [
        ("managed", "Managed", "Cloudflare decides when to challenge users with an interactive checkbox."),
        ("non-interactive", "Non-Interactive", "Users see a loading spinner while verification is run silently."),
        ("invisible", "Invisible", "Verification is completely hidden in the background without UI elements.")
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General Information")) {
                    TextField("Widget Name (e.g. My Website Login)", text: $widgetName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Widget Mode"), footer: Text(modes.first(where: { $0.0 == selectedMode })?.2 ?? "")) {
                    Picker("Challenge Mode", selection: $selectedMode) {
                        ForEach(modes, id: \.0) { mode in
                            Text(mode.1).tag(mode.0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Allowed Domains"), footer: Text("Enter hostnames allowed to display this Turnstile widget, separated by comma or newlines.")) {
                    TextField("Domains (e.g. example.com, app.example.com)", text: $domainsText, axis: .vertical)
                        .lineLimit(2...4)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Turnstile Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(widgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .toastContainer()
        }
    }
    
    // MARK: - Actions
    private func submit() {
        let name = widgetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let domains = domainsText
            .split(separator: ",")
            .flatMap { $0.split(separator: "\n") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        isSubmitting = true
        Task {
            do {
                _ = try await viewModel.createWidget(name: name, domains: domains.isEmpty ? ["*"] : domains, mode: selectedMode)
                HapticManager.impact(.medium)
                CloudnsToastManager.shared.showSuccess("Widget Created", message: name)
                dismiss()
            } catch {
                CloudnsToastManager.shared.showError("Creation Failed", message: error.localizedDescription)
            }
            isSubmitting = false
        }
    }
}
