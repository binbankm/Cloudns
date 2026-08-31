import SwiftUI

// MARK: - WorkerSecretsView

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
                    .higToast()
            }
            .sheet(item: $variableToEdit) { v in
                WorkerEditVariableSheetView(viewModel: viewModel, variable: v)
                    .higToast()
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
                                HIGFeedback.success()
                            } catch {
                                ToastManager.shared.showError("Failed to delete")
                                HIGFeedback.error()
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
                            HIGFeedback.impact(.light)
                            variableToEdit = item
                        } label: {
                            variableRow(name: item.name, value: item.text, isSecret: false)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if let val = item.text {
                                Button {
                                    UIPasteboard.general.string = val
                                    ToastManager.shared.showCopied()
                                    HIGFeedback.impact(.light)
                                } label: {
                                    Label("Copy Value", systemImage: "doc.on.doc")
                                }
                            }
                            Button {
                                UIPasteboard.general.string = item.name
                                ToastManager.shared.showCopied()
                                HIGFeedback.impact(.light)
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
                                HIGFeedback.impact(.medium)
                                itemToDelete = (item.name, false)
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
                                    UIPasteboard.general.string = secret.name
                                    ToastManager.shared.showCopied()
                                    HIGFeedback.impact(.light)
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
                                    HIGFeedback.impact(.medium)
                                    itemToDelete = (secret.name, true)
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Variables & Secrets..."))
            } else if viewModel.hasFetchedData && viewModel.plainVariables.isEmpty && viewModel.secrets.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Variables or Secrets",
                        systemImage: "key.fill",
                        description: "Configure plaintext environment variables and encrypted secrets for this Worker.",
                        actionTitle: "Add Variable or Secret",
                        action: { showingAddSheet = true }
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private func variableRow(name: String, value: String?, isSecret: Bool) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(
                icon: isSecret ? "lock.fill" : "textformat",
                color: isSecret ? .purple : .blue,
                size: 28,
                cornerRadius: 6
            )
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.body.monospaced().weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if isSecret {
                        HIGBadge(.custom(color: .purple, text: "Secret"), isCompact: true)
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
        .padding(.vertical, 3)
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
                    
                    if isSecret {
                        SecureField("Secret Value", text: $value)
                    } else {
                        TextField("Value", text: $value)
                            .autocorrectionDisabled()
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
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
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
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
