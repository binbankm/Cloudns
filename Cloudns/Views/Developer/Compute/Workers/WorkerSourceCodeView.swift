import SwiftUI

// MARK: - WorkerSourceCodeView
// Apple HIG Compliant Cloudflare Worker ESM Module & Code Editor

struct WorkerSourceCodeView: View {
    @ObservedObject var parentViewModel: WorkerDetailViewModel
    let scriptName: String
    let modules: [WorkerModuleItem]
    let singleScriptContent: String
    
    @State private var selectedModule: WorkerModuleItem?
    @State private var currentCode: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(
        parentViewModel: WorkerDetailViewModel,
        scriptName: String,
        modules: [WorkerModuleItem],
        singleScriptContent: String
    ) {
        self.parentViewModel = parentViewModel
        self.scriptName = scriptName
        self.modules = modules
        self.singleScriptContent = singleScriptContent
        
        let initialMod = modules.first(where: { $0.isMain }) ?? modules.first
        _selectedModule = State(initialValue: initialMod)
        _currentCode = State(initialValue: initialMod?.code ?? singleScriptContent)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !modules.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        ForEach(modules) { module in
                            Button {
                                selectedModule = module
                                currentCode = module.code
                                HIGFeedback.selection()
                            } label: {
                                HStack(spacing: HIGTokens.Spacing.xxs) {
                                    Image(systemName: module.isMain ? "star.fill" : "doc.text")
                                        .font(HIGTypography.caption2)
                                    Text(module.name)
                                        .font(HIGTypography.caption.monospaced())
                                }
                                .padding(.horizontal, HIGTokens.Spacing.sm + 2)
                                .padding(.vertical, HIGTokens.Spacing.xxs + 2)
                                .background(selectedModule?.id == module.id ? Color.higAccent : Color(.secondarySystemFill))
                                .foregroundStyle(selectedModule?.id == module.id ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .higTouchTarget(44)
                        }
                    }
                    .padding(.horizontal, HIGTokens.Spacing.md)
                    .padding(.vertical, HIGTokens.Spacing.sm)
                }
                .background(Color(.secondarySystemBackground))
                
                Divider()
            }
            
            TextEditor(text: $currentCode)
                .font(HIGTypography.caption.monospaced())
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
                .padding(HIGTokens.Spacing.sm)
        }
        .navigationTitle(scriptName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Button {
                        UIPasteboard.general.string = currentCode
                        ToastManager.shared.showCopied("Code Copied")
                        HIGFeedback.copied()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .accessibilityLabel("Copy Code")
                    .higTouchTarget(44)
                    
                    Button {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await parentViewModel.deployScript(
                                    code: currentCode,
                                    isModule: !modules.isEmpty
                                )
                                ToastManager.shared.showSuccess("Script Deployed", icon: "arrow.up.circle.fill")
                                HIGFeedback.success()
                            } catch {
                                errorMessage = error.localizedDescription
                                ToastManager.shared.showError("Deploy Failed")
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.higAccent)
                        }
                    }
                    .disabled(isSaving)
                    .higTouchTarget(44)
                }
            }
        }
    }
}
