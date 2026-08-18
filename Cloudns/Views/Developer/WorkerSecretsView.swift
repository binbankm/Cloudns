import SwiftUI

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
        List {
            // Segment Picker
            Section {
                Picker("Type", selection: $viewModel.selectedTab) {
                    Text(viewModel.hasFetchedData ? "Variables (\(viewModel.plainVariables.count))" : "Variables").tag("variables")
                    Text(viewModel.hasFetchedData ? "Secrets (\(viewModel.secrets.count))" : "Secrets").tag("secrets")
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            
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
                        .skeletonLoading(true)
                    }
                }
            } else if viewModel.selectedTab == "variables" {
                if !viewModel.filteredVariables.isEmpty {
                    variablesSection
                }
            } else {
                if !viewModel.filteredSecrets.isEmpty {
                    secretsSection
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Variables & Secrets")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Variables & Secrets")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
                        ToastManager.shared.showSuccess("Deleted", message: item.name)
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
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
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.plainVariables.isEmpty && viewModel.secrets.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchSecrets() }
                            }
                        )
                    )
                } else if viewModel.selectedTab == "variables" {
                    if viewModel.plainVariables.isEmpty {
                        StateOverlayView(
                            state: .empty(
                                icon: "slider.horizontal.3",
                                title: "No Plaintext Variables",
                                message: "Plaintext environment variables are readable in code and configuration.",
                                actionTitle: "Add Variable",
                                action: { showingAddSheet = true }
                            )
                        )
                    } else if viewModel.filteredVariables.isEmpty && !viewModel.searchText.isEmpty {
                        StateOverlayView(
                            state: .search(
                                query: viewModel.searchText,
                                clearAction: { viewModel.searchText = "" }
                            )
                        )
                    }
                } else {
                    if viewModel.secrets.isEmpty {
                        StateOverlayView(
                            state: .empty(
                                icon: "key.fill",
                                title: "No Encrypted Secrets",
                                message: "Secrets are encrypted upon saving and cannot be retrieved or read back by the API.",
                                actionTitle: "Add Secret",
                                action: { showingAddSheet = true }
                            )
                        )
                    } else if viewModel.filteredSecrets.isEmpty && !viewModel.searchText.isEmpty {
                        StateOverlayView(
                            state: .search(
                                query: viewModel.searchText,
                                clearAction: { viewModel.searchText = "" }
                            )
                        )
                    }
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSecrets()
            }
        }
    }
    
    // MARK: - Plaintext Variables Section
    
    @ViewBuilder
    private var variablesSection: some View {
        Section(
            header: Text("Plaintext Variables (\(viewModel.filteredVariables.count))"),
            footer: Text("Environment variables are plaintext strings accessible via global env bindings in your script.")
        ) {
            ForEach(viewModel.filteredVariables) { variable in
                variableRow(variable)
            }
        }
    }
    
    @ViewBuilder
    private func variableRow(_ variable: WorkerBinding) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(variable.name)
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundStyle(.primary)
                
                if let val = variable.text {
                    Text(val)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button {
                variableToEdit = variable
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit variable \(variable.name)")
        }
        .padding(.vertical, 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                HapticManager.impact(.medium)
                itemToDelete = (variable.name, false)
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            if let val = variable.text {
                Button {
                    UIPasteboard.general.string = val
                    HapticManager.notification(.success)
                    ToastManager.shared.showCopied("Variable value copied")
                } label: {
                    Label("Copy Value", systemImage: "doc.on.doc")
                }
            }
            Button {
                variableToEdit = variable
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
    }
    
    // MARK: - Encrypted Secrets Section
    
    @ViewBuilder
    private var secretsSection: some View {
        Section(
            header: Text("Encrypted Secrets (\(viewModel.filteredSecrets.count))"),
            footer: Text("Secret values are strictly write-only and encrypted. To change a value, simply save a new value under the same secret name.")
        ) {
            ForEach(viewModel.filteredSecrets) { secret in
                secretRow(secret)
            }
        }
    }
    
    @ViewBuilder
    private func secretRow(_ secret: WorkerSecret) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "key.fill")
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 30, height: 30)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(secret.name)
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundStyle(.primary)
                
                if let mod = secret.modifiedOn {
                    Text("Modified: \(DateFormatters.formatISO8601ToDisplay(mod, style: DateFormatters.dateOnly))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("ENCRYPTED")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 3)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                HapticManager.impact(.medium)
                itemToDelete = (secret.name, true)
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = secret.name
                HapticManager.notification(.success)
                ToastManager.shared.showCopied("Secret name copied")
            } label: {
                Label("Copy Name", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Add Variable or Secret Sheet

struct WorkerAddVariableOrSecretSheetView: View {
    @ObservedObject var viewModel: WorkerSecretsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSecret = false
    @State private var itemName = ""
    @State private var itemValue = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Type")) {
                    Picker("Type", selection: $isSecret) {
                        Text("Plaintext Variable").tag(false)
                        Text("Encrypted Secret").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text(isSecret ? "Secret Key Name" : "Variable Key Name")) {
                    TextField("KEY_NAME", text: $itemName)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                Section(
                    header: Text(isSecret ? "Secret Value (Encrypted)" : "Variable Value (Plaintext)"),
                    footer: Text(isSecret ? "Secrets cannot be viewed after saving. Use for API keys, tokens and passwords." : "Plaintext variables can be read, viewed, and modified at any time.")
                ) {
                    if isSecret {
                        SecureField("Secret Value", text: $itemValue)
                            .textContentType(.password)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                    } else {
                        TextField("Variable Value", text: $itemValue, axis: .vertical)
                            .lineLimit(2...5)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.never)
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
            .navigationTitle(isSecret ? "Add Secret" : "Add Variable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty || itemValue.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
    
    private func save() {
        isSaving = true
        errorMessage = nil
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                if isSecret {
                    try await viewModel.saveSecret(name: name, value: itemValue)
                    viewModel.selectedTab = "secrets"
                } else {
                    try await viewModel.savePlainVariable(name: name, value: itemValue)
                    viewModel.selectedTab = "variables"
                }
                HapticManager.impact(.medium)
                ToastManager.shared.showSuccess("Saved", message: name)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - Edit Variable Sheet

struct WorkerEditVariableSheetView: View {
    @ObservedObject var viewModel: WorkerSecretsViewModel
    let variable: WorkerBinding
    @Environment(\.dismiss) private var dismiss
    
    @State private var variableValue: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(viewModel: WorkerSecretsViewModel, variable: WorkerBinding) {
        self.viewModel = viewModel
        self.variable = variable
        _variableValue = State(initialValue: variable.text ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Variable Key")) {
                    Text(variable.name)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                Section(header: Text("Variable Value (Plaintext)")) {
                    TextField("Value", text: $variableValue, axis: .vertical)
                        .lineLimit(3...6)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
    
    private func save() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await viewModel.savePlainVariable(name: variable.name, value: variableValue)
                HapticManager.impact(.medium)
                ToastManager.shared.showSuccess("Updated", message: variable.name)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
