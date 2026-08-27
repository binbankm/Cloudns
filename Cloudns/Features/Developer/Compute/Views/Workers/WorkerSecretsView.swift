import SwiftUI

struct WorkerSecretsView: View {
    // MARK: - Properties
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
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search Variables & Secrets"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            Picker("Type", selection: $viewModel.selectedTab) {
                Text(viewModel.hasFetchedData ? "Variables (\(viewModel.plainVariables.count))" : "Variables").tag("variables")
                Text(viewModel.hasFetchedData ? "Secrets (\(viewModel.secrets.count))" : "Secrets").tag("secrets")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, CloudnsSpacing.sm)
            .background(CloudnsColor.groupedBackground)
            
            contentList
                .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
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
                        CloudnsToastManager.shared.showSuccess("Deleted", message: item.name)
                    } catch {
                        CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
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
    // MARK: - Private Views
    private var contentList: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Variables & Secrets")) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack {
                            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
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
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.plainVariables.isEmpty && viewModel.secrets.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchSecrets() }
                            }
                        )
                    )
                } else if viewModel.selectedTab == "variables" {
                    if viewModel.plainVariables.isEmpty {
                        CloudnsStateOverlayView(
                            state: .empty(
                                icon: "slider.horizontal.3",
                                title: "No Plaintext Variables",
                                message: "Plaintext environment variables are readable in code and configuration.",
                                actionTitle: "Add Variable",
                                action: { showingAddSheet = true }
                            )
                        )
                    } else if viewModel.filteredVariables.isEmpty && !viewModel.searchText.isEmpty {
                        CloudnsStateOverlayView(
                            state: .search(
                                query: viewModel.searchText,
                                clearAction: { viewModel.searchText = "" }
                            )
                        )
                    }
                } else {
                    if viewModel.secrets.isEmpty {
                        CloudnsStateOverlayView(
                            state: .empty(
                                icon: "key.fill",
                                title: "No Encrypted Secrets",
                                message: "Secrets are encrypted upon saving and cannot be retrieved or read back by the API.",
                                actionTitle: "Add Secret",
                                action: { showingAddSheet = true }
                            )
                        )
                    } else if viewModel.filteredSecrets.isEmpty && !viewModel.searchText.isEmpty {
                        CloudnsStateOverlayView(
                            state: .search(
                                query: viewModel.searchText,
                                clearAction: { viewModel.searchText = "" }
                            )
                        )
                    }
                }
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
        HStack(alignment: .center, spacing: CloudnsSpacing.mdMedium) {
            Image(systemName: "slider.horizontal.3")
                .font(.body)
                .foregroundStyle(CloudnsColor.brand)
                .frame(width: CloudnsSize.avatarSmall, height: CloudnsSize.avatarSmall)
                .background(CloudnsColor.brandMuted)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
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
                    .foregroundStyle(CloudnsColor.brand)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit variable \(variable.name)")
        }
        .padding(.vertical, CloudnsSpacing.xs)
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
                    CloudnsToastManager.shared.showCopied("Variable value copied")
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
        HStack(alignment: .center, spacing: CloudnsSpacing.mdMedium) {
            Image(systemName: "key.fill")
                .font(.body)
                .foregroundStyle(CloudnsColor.brandAccent)
                .frame(width: CloudnsSize.avatarSmall, height: CloudnsSize.avatarSmall)
                .background(CloudnsColor.warningMuted)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
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
                .foregroundStyle(CloudnsColor.success)
                .padding(.horizontal, CloudnsSpacing.xs)
                .padding(.vertical, CloudnsSpacing.xxs)
                .background(CloudnsColor.successMuted)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
        }
        .padding(.vertical, CloudnsSpacing.xs)
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
                CloudnsToastManager.shared.showCopied("Secret name copied")
            } label: {
                Label("Copy Name", systemImage: "doc.on.doc")
            }
        }
    }
}
