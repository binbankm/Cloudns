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
                            .foregroundColor(.secondary)
                        TextField("npm run build / hugo / next build", text: $buildCommand)
                            .font(.body.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.vertical, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Build Output Directory")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("dist / public / .next", text: $destinationDir)
                            .font(.body.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.vertical, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Root Directory (Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("/", text: $rootDir)
                            .font(.body.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.vertical, 2)
                }
                
                Section(header: Text("Source Configuration")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Production Branch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("main / master", text: $productionBranch)
                            .font(.body.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.vertical, 2)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Build Configuration")
            .navigationBarTitleDisplayMode(.inline)
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
                                try await CloudflareAPIClient.shared.updatePagesProject(
                                    accountId: accountId,
                                    projectName: project.name,
                                    buildCommand: buildCommand.isEmpty ? nil : buildCommand,
                                    destinationDir: destinationDir.isEmpty ? nil : destinationDir,
                                    rootDir: rootDir.isEmpty ? nil : rootDir,
                                    productionBranch: productionBranch.isEmpty ? nil : productionBranch
                                )
                                ToastManager.shared.showSuccess("Build Config Saved", message: project.name)
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
