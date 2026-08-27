import SwiftUI

// MARK: - EditTurnstileWidgetSheetView

struct EditTurnstileWidgetSheetView: View {
    @ObservedObject var viewModel: TurnstileViewModel
    let widget: TurnstileWidget
    var onUpdated: (TurnstileWidget) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var widgetName: String
    @State private var domainsText: String
    @State private var selectedMode: String
    @State private var isSubmitting = false
    
    private let modes = [
        ("managed", "Managed"),
        ("non-interactive", "Non-Interactive"),
        ("invisible", "Invisible")
    ]
    
    init(viewModel: TurnstileViewModel, widget: TurnstileWidget, onUpdated: @escaping (TurnstileWidget) -> Void) {
        self.viewModel = viewModel
        self.widget = widget
        self.onUpdated = onUpdated
        _widgetName = State(initialValue: widget.name)
        _domainsText = State(initialValue: widget.domains?.joined(separator: ", ") ?? "")
        _selectedMode = State(initialValue: widget.mode ?? "managed")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General Information")) {
                    TextField("Widget Name", text: $widgetName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Widget Mode")) {
                    Picker("Challenge Mode", selection: $selectedMode) {
                        ForEach(modes, id: \.0) { mode in
                            Text(mode.1).tag(mode.0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Allowed Domains"), footer: Text("Hostnames allowed to use this widget.")) {
                    TextField("Domains (e.g. example.com, app.example.com)", text: $domainsText, axis: .vertical)
                        .lineLimit(2...4)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Widget")
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
                            Text("Save")
                        }
                    }
                    .disabled(widgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }
    
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
                try await viewModel.updateWidget(sitekey: widget.sitekey, name: name, domains: domains.isEmpty ? ["*"] : domains, mode: selectedMode)
                let updated = TurnstileWidget(sitekey: widget.sitekey, name: name, mode: selectedMode, domains: domains.isEmpty ? ["*"] : domains, secret: widget.secret, createdOn: widget.createdOn, modifiedOn: widget.modifiedOn)
                onUpdated(updated)
                HapticManager.impact(.medium)
                CloudnsToastManager.shared.showSuccess("Widget Updated", message: name)
                dismiss()
            } catch {
                CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
            }
            isSubmitting = false
        }
    }
}
