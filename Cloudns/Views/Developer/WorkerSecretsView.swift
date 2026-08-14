import SwiftUI

struct WorkerSecretsView: View {
    let accountId: String
    let scriptName: String
    @StateObject private var viewModel: WorkerSecretsViewModel
    @State private var showingAddSheet = false
    @State private var secretToDelete: WorkerSecret? = nil
    @State private var showingDeleteAlert = false
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerSecretsViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    var body: some View {
        contentView
            .navigationTitle("Environment Secrets")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Secrets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                WorkerAddSecretSheetView(viewModel: viewModel)
            }
            .alert("Delete Secret", isPresented: $showingDeleteAlert, presenting: secretToDelete) { secret in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteSecret(name: secret.name)
                            ToastManager.shared.showSuccess("Secret Deleted", message: secret.name)
                        } catch {
                            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                        }
                    }
                }
            } message: { secret in
                Text("Are you sure you want to delete secret '\(secret.name)'? Secret values cannot be read back once deleted.")
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
    private var contentView: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchSecrets() }
                    }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if viewModel.secrets.isEmpty {
                EmptyStateView(
                    icon: "key.fill",
                    title: "No Secrets Found",
                    message: "You haven't defined any encrypted environment variables (secrets) for this Worker yet.",
                    actionTitle: "Add Secret",
                    action: { showingAddSheet = true }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if viewModel.filteredSecrets.isEmpty {
                EmptyStateView.search(query: viewModel.searchText) {
                    viewModel.searchText = ""
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                Section(header: Text("Encrypted Secrets (\(viewModel.secrets.count))"), footer: Text("Secrets are encrypted and exposed as environment variables to your Worker script at runtime.")) {
                    ForEach(viewModel.filteredSecrets) { secret in
                        HStack(alignment: .center, spacing: 14) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                                .frame(width: 30, height: 30)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(secret.name)
                                    .font(.body.monospaced())
                                    .foregroundColor(.primary)
                                
                                if let mod = secret.modifiedOn {
                                    Text("Modified: \(String(mod.prefix(10)))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("ENCRYPTED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 3)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                secretToDelete = secret
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = secret.name
                                ToastManager.shared.showCopied("Secret name copied")
                            } label: {
                                Label("Copy Name", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct WorkerAddSecretSheetView: View {
    @ObservedObject var viewModel: WorkerSecretsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var secretName = ""
    @State private var secretValue = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Secret Key")) {
                    TextField("VARIABLE_NAME", text: $secretName)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Secret Value"), footer: Text("Values are encrypted upon saving and cannot be retrieved or read back.")) {
                    SecureField("Value", text: $secretValue)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Secret Variable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await viewModel.saveSecret(
                                    name: secretName.trimmingCharacters(in: .whitespaces),
                                    value: secretValue
                                )
                                ToastManager.shared.showSuccess("Worker Secrets", message: "Secret saved successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(secretName.trimmingCharacters(in: .whitespaces).isEmpty || secretValue.isEmpty || isSaving)
                }
            }
            .toastContainer()
        }
    }
}
