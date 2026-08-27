import SwiftUI

// MARK: - AddCORSRuleSheetView

struct AddCORSRuleSheetView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: R2BucketSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var originText = "*"
    @State private var selectedMethods: Set<String> = ["GET", "HEAD"]
    @State private var headersText = "*"
    @State private var maxAgeSeconds = 3600
    @State private var isSaving = false
    
    let allMethods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Allowed Origins"), footer: Text("Comma-separated origins (e.g. https://example.com, *)")) {
                    TextField("https://example.com or *", text: $originText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Allowed HTTP Methods")) {
                    ForEach(allMethods, id: \.self) { method in
                        Toggle(method, isOn: Binding(
                            get: { selectedMethods.contains(method) },
                            set: { isSelected in
                                if isSelected { selectedMethods.insert(method) } else { selectedMethods.remove(method) }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Allowed Headers"), footer: Text("Comma-separated headers (e.g. Content-Type, Authorization, *)")) {
                    TextField("Content-Type or *", text: $headersText)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Max-Age (Seconds)")) {
                    Stepper("\(maxAgeSeconds) seconds", value: $maxAgeSeconds, in: 0...86400, step: 300)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New CORS Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            let origins = originText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            let headers = headersText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            let rule = R2CORSRule(
                                allowedOrigins: origins.isEmpty ? ["*"] : origins,
                                allowedMethods: Array(selectedMethods),
                                allowedHeaders: headers.isEmpty ? nil : headers,
                                exposeHeaders: nil,
                                maxAgeSeconds: maxAgeSeconds
                            )
                            let success = await viewModel.saveCORSRule(rule: rule)
                            if success { dismiss() }
                            isSaving = false
                        }
                    }
                    .disabled(selectedMethods.isEmpty || originText.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
}
