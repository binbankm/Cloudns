import SwiftUI

// MARK: - WorkerSecretsView
// Apple HIG Compliant Cloudflare Worker Plaintext Environment & Encrypted Secret Keyring

struct WorkerSecretsView: View {
    let accountId: String
    let scriptName: String
    @StateObject private var viewModel: WorkerSecretsViewModel
    @State private var showingAddSheet = false
    @State private var variableToEdit: WorkerBinding?
    @State private var itemToDelete: (name: String, isSecret: Bool)?
    @State private var showingDeleteAlert = false
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerSecretsViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    var body: some View {
        contentList
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Variables & Secrets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Variable or Secret")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                WorkerAddVariableOrSecretSheetView(viewModel: viewModel)
            }
            .sheet(item: $variableToEdit) { v in
                WorkerEditVariableSheetView(viewModel: viewModel, variable: v)
            }
            .confirmationDialog("Delete Item", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                if let item = itemToDelete {
                    Button("Delete '\(item.name)'", role: .destructive) {
                        Task {
                            do {
                                if item.isSecret {
                                    try await viewModel.deleteSecret(name: item.name)
                                } else {
                                    try await viewModel.deletePlainVariable(name: item.name)
                                }
                                ToastManager.shared.showSuccess("Deleted '\(item.name)'", icon: "trash.fill")
                                HapticManager.notification(.success)
                            } catch {
                                ToastManager.shared.showError("Failed to Delete")
                                HapticManager.notification(.error)
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let item = itemToDelete {
                    if item.isSecret {
                        Text("Are you sure you want to delete secret '\(item.name)'?")
                    } else {
                        Text("Are you sure you want to delete variable '\(item.name)'?")
                    }
                }
            }
            .refreshable {
                await viewModel.fetchSecrets()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchSecrets()
                }
            }
    }
    
    @ViewBuilder
    private var contentList: some View {
        List {
            // MARK: - Plaintext Variables
            if !viewModel.plainVariables.isEmpty {
                Section(header: Text("Plaintext Variables (\(viewModel.plainVariables.count))")) {
                    ForEach(viewModel.plainVariables) { item in
                        Button {
                            HapticManager.impact(.light)
                            variableToEdit = item
                        } label: {
                            variableRow(name: item.name, value: item.text, isSecret: false)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if let val = item.text {
                                Button {
                                    copyToClipboard(val, toast: "Value Copied")
                                } label: {
                                    Label("Copy Value", systemImage: "doc.on.doc")
                                }
                            }
                            Button {
                                copyToClipboard(item.name, toast: "Key Name Copied")
                            } label: {
                                Label("Copy Key Name", systemImage: "doc.on.doc")
                            }
                            Button {
                                variableToEdit = item
                            } label: {
                                Label("Edit Variable", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                itemToDelete = (item.name, false)
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Variable", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                itemToDelete = (item.name, false)
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
            
            // MARK: - Encrypted Secrets
            if !viewModel.secrets.isEmpty {
                Section(header: Text("Encrypted Secrets (\(viewModel.secrets.count))")) {
                    ForEach(viewModel.secrets) { secret in
                        variableRow(name: secret.name, value: nil, isSecret: true)
                            .contextMenu {
                                Button {
                                    copyToClipboard(secret.name, toast: "Secret Name Copied")
                                } label: {
                                    Label("Copy Secret Name", systemImage: "doc.on.doc")
                                }
                                Button(role: .destructive) {
                                    itemToDelete = (secret.name, true)
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Secret", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    itemToDelete = (secret.name, true)
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Variables & Secrets…",
            isEmpty: viewModel.hasFetchedData && viewModel.plainVariables.isEmpty && viewModel.secrets.isEmpty,
            emptyTitle: "No Variables or Secrets",
            emptySystemImage: "key.fill",
            emptyDescription: "Configure plaintext environment variables and encrypted secrets for this Worker.",
            emptyActionTitle: "Add Variable or Secret",
            emptyAction: { showingAddSheet = true }
        )
    }
    
    @ViewBuilder
    private func variableRow(name: String, value: String?, isSecret: Bool) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(
                icon: isSecret ? "lock.fill" : "textformat",
                color: isSecret ? .purple : .blue
            )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.body.monospaced().weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if isSecret {
                        Text("Secret")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.purple.opacity(0.12)))
                    }
                }
                
                if isSecret {
                    Text("••••••••••••••••")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                } else if let txt = value, !txt.isEmpty {
                    Text(txt)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if !isSecret {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

// MARK: - WorkerAddVariableOrSecretSheetView (Inlined & Cohesive)

struct WorkerAddVariableOrSecretSheetView: View {
    @ObservedObject var viewModel: WorkerSecretsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var value = ""
    @State private var isSecret = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Type")) {
                    Picker("Binding Kind", selection: $isSecret) {
                        Text("Plaintext Variable").tag(false)
                        Text("Encrypted Secret").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Configuration")) {
                    TextField("Name (e.g. API_KEY)", text: $name)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                    
                    if isSecret {
                        SecureField("Secret Value", text: $value)
                            .font(.body.monospaced())
                    } else {
                        TextField("Value", text: $value)
                            .autocorrectionDisabled()
                            .font(.body.monospaced())
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Variable / Secret")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                if isSecret {
                                    try await viewModel.saveSecret(name: name.trimmingCharacters(in: .whitespaces), value: value)
                                } else {
                                    try await viewModel.savePlainVariable(name: name.trimmingCharacters(in: .whitespaces), value: value)
                                }
                                ToastManager.shared.showSuccess(isSecret ? LocalizedStringKey("Secret Saved") : LocalizedStringKey("Variable Saved"), icon: "checkmark.circle.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}

// MARK: - WorkerEditVariableSheetView (Inlined & Cohesive)

struct WorkerEditVariableSheetView: View {
    @ObservedObject var viewModel: WorkerSecretsViewModel
    let variable: WorkerBinding
    @Environment(\.dismiss) private var dismiss
    
    @State private var value: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(viewModel: WorkerSecretsViewModel, variable: WorkerBinding) {
        self.viewModel = viewModel
        self.variable = variable
        _value = State(initialValue: variable.text ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Variable Name")) {
                    Text(variable.name)
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                }
                
                Section(header: Text("Value")) {
                    TextField("Value", text: $value)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Variable")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await viewModel.savePlainVariable(name: variable.name, value: value)
                                ToastManager.shared.showSuccess("Variable Updated", icon: "checkmark.circle.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
