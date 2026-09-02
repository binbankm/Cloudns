import SwiftUI

// MARK: - PagesBuildConfigEditorView
// Apple HIG Compliant Cloudflare Pages Build & Deployment Settings Form

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
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                        Text("Build Command")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                        TextField("npm run build / hugo / next build", text: $buildCommand)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .font(HIGTypography.body.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: "command")
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                    
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                        Text("Build Output Directory")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                        TextField("dist / public / .next", text: $destinationDir)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .font(HIGTypography.body.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: "output")
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                    
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                        Text("Root Directory (Optional)")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                        TextField("/", text: $rootDir)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .font(HIGTypography.body.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: "root")
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                }
                
                Section(header: Text("Source Configuration")) {
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                        Text("Production Branch")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                        TextField("main / master", text: $productionBranch)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .font(HIGTypography.body)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: "branch")
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                }
                
                if let error = errorMessage {
                    Section {
                        HStack(spacing: HIGTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HIGColors.error)
                            Text(verbatim: error)
                                .font(HIGTypography.footnote)
                                .foregroundStyle(HIGColors.error)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Build Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HIGFeedback.impact(.medium)
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
                                ToastManager.shared.showSuccess("Configuration Saved", icon: "gearshape.fill")
                                HIGFeedback.success()
                                await parentViewModel.fetchProjectDetails()
                                dismiss()
                            } catch {
                                HIGFeedback.error()
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
        .higToast()
    }
}
