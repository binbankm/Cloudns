import SwiftUI

struct PagesBuildConfigEditorView: View {
    let accountId: String
    let project: PagesProject
    @ObservedObject var parentViewModel: PagesProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var buildCommand: String = ""
    @State private var destinationDir: String = ""
    @State private var rootDir: String = ""
    @State private var productionBranch: String = ""
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: String?
    
    init(accountId: String, project: PagesProject, parentViewModel: PagesProjectDetailViewModel) {
        self.accountId = accountId
        self.project = project
        self.parentViewModel = parentViewModel
        _buildCommand = State(initialValue: project.buildConfig?.buildCommand ?? "")
        _destinationDir = State(initialValue: project.buildConfig?.destinationDir ?? "")
        _rootDir = State(initialValue: project.buildConfig?.rootDir ?? "")
        _productionBranch = State(initialValue: project.productionBranch ?? "main")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Build Settings"), footer: Text("Configure build commands and directories executed during automated deployment.")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Build Command")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("npm run build / hugo / next build", text: $buildCommand)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .font(.body)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: "command")
                    }
                    .padding(.vertical, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Build Output Directory")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("dist / public / .next", text: $destinationDir)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .font(.body)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: "output")
                    }
                    .padding(.vertical, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Root Directory (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("/", text: $rootDir)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .font(.body)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: "root")
                    }
                    .padding(.vertical, 2)
                }
                
                Section(header: Text("Source Configuration")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Production Branch")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("main / master", text: $productionBranch)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .font(.body)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: "branch")
                    }
                    .padding(.vertical, 2)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
            .navigationTitle("Build Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.impact(.medium)
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await PagesService.shared.updatePagesProject(
                                    accountId: accountId,
                                    projectName: project.name,
                                    buildCommand: buildCommand.isEmpty ? nil : buildCommand,
                                    destinationDir: destinationDir.isEmpty ? nil : destinationDir,
                                    rootDir: rootDir.isEmpty ? nil : rootDir,
                                    productionBranch: productionBranch.isEmpty ? nil : productionBranch
                                )
                                HapticManager.impact(.medium)
                                CloudnsToastManager.shared.showSuccess("Build Config Saved", message: project.name)
                                await parentViewModel.fetchProjectDetails()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .toastContainer()
        }
    }
}
