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
        let varsTitle = viewModel.hasFetchedData ? "Variables (\(viewModel.plainVariables.count))" : "Variables"
        let secretsTitle = viewModel.hasFetchedData ? "Secrets (\(viewModel.secrets.count))" : "Secrets"
        
        VStack(spacing: 0) {
            Picker("Type", selection: $viewModel.selectedTab) {
                Text(varsTitle).tag("variables")
                Text(secretsTitle).tag("secrets")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            .onChange(of: viewModel.selectedTab) { _ in
                HIGFeedback.selection()
            }
            
            contentList
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Variables & Secrets"
        )
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
        .confirmationDialog("Delete Item", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: itemToDelete) { item in
            Button("Delete '\(item.name)'", role: .destructive) {
                Task {
                    do {
                        if item.isSecret {
                            try await viewModel.deleteSecret(name: item.name)
                        } else {
                            try await viewModel.deletePlainVariable(name: item.name)
                        }
                        HIGFeedback.success()
                    } catch {
                        HIGFeedback.error()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("Are you sure you want to delete \(item.isSecret ? "secret" : "environment variable") '\(item.name)'?")
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Variables & Secrets")) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SECRET_KEY_PLACEHOLDER")
                                    .font(.headline)
                                Text("••••••••••••••••")
                                    .font(.subheadline)
                            }
                            Spacer()
                        }
                        .redacted(reason: .placeholder)
                    }
                }
            } else if viewModel.selectedTab == "variables" {
                if !viewModel.filteredVariables.isEmpty {
                    Section(header: Text("Plaintext Variables (\(viewModel.filteredVariables.count))")) {
                        ForEach(viewModel.filteredVariables) { item in
                            Button {
                                variableToEdit = item
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        
                                        if let text = item.text {
                                            Text(text)
                                                .font(.caption.monospaced())
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.tertiary)
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
            } else {
                if !viewModel.filteredSecrets.isEmpty {
                    Section(header: Text("Encrypted Secrets (\(viewModel.filteredSecrets.count))")) {
                        ForEach(viewModel.filteredSecrets) { secret in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(secret.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("••••••••••••••••")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                HIGBadge(.custom(color: .indigo, text: "Secret"), isCompact: true)
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
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.hasFetchedData {
                if viewModel.selectedTab == "variables" && viewModel.plainVariables.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Variables",
                            systemImage: "slider.horizontal.3",
                            description: "Plaintext environment variables accessible via env.VAR_NAME.",
                            actionTitle: "Add Variable",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if viewModel.selectedTab == "secrets" && viewModel.secrets.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Secrets",
                            systemImage: "lock.shield",
                            description: "Encrypted environment variables encrypted at rest and in transit.",
                            actionTitle: "Add Secret",
                            action: { showingAddSheet = true }
                        )
                    )
                }
            }
        }
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
