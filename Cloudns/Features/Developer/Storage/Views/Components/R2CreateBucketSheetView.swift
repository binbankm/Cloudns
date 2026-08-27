import SwiftUI

// MARK: - R2CreateBucketSheetView

struct R2CreateBucketSheetView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: R2ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var bucketName = ""
    @State private var selectedLocation = "auto"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let locations = [
        ("auto", "Automatic (Best Available)"),
        ("wnam", "Western North America"),
        ("enam", "Eastern North America"),
        ("weur", "Western Europe"),
        ("eeur", "Eastern Europe"),
        ("apac", "Asia-Pacific")
    ]
    
    private var normalizedBucketName: String {
        bucketName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private var isValidBucketName: Bool {
        let name = normalizedBucketName
        guard name.count >= 3 && name.count <= 63 else { return false }
        let pattern = "^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$"
        return name.range(of: pattern, options: .regularExpression) != nil
    }
    
    private var validationHint: String? {
        let name = normalizedBucketName
        if name.isEmpty {
            return nil
        }
        if name.count < 3 {
            return "Bucket name must be at least 3 characters long."
        }
        if name.count > 63 {
            return "Bucket name cannot exceed 63 characters."
        }
        let pattern = "^[a-z0-9][a-z0-9-]*[a-z0-9]$"
        if name.range(of: pattern, options: .regularExpression) == nil {
            return "Only lowercase letters, numbers, and hyphens (-) allowed. Cannot start or end with a hyphen."
        }
        return nil
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bucket Information"), footer: Text("3-63 characters, lowercase letters, numbers, and hyphens only.")) {
                    TextField("my-bucket-name", text: $bucketName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onChange(of: bucketName) { newValue in
                            let lower = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                            if lower != newValue {
                                bucketName = lower
                            }
                        }
                    
                    Picker("Location Hint", selection: $selectedLocation) {
                        ForEach(locations, id: \.0) { loc in
                            Text(loc.1).tag(loc.0)
                        }
                    }
                }
                
                if let hint = validationHint {
                    Section {
                        Label(hint, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(CloudnsColor.brandAccent)
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(CloudnsColor.danger)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create R2 Bucket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                let locHint = selectedLocation == "auto" ? nil : selectedLocation
                                try await viewModel.createBucket(name: normalizedBucketName, locationHint: locHint)
                                CloudnsToastManager.shared.showSuccess("R2 Storage", message: "Bucket created successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(!isValidBucketName || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
            .toastContainer()
        }
    }
}
