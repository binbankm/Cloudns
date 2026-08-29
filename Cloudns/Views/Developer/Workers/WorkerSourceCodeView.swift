import SwiftUI

// MARK: - WorkerSourceCodeView

struct WorkerSourceCodeView: View {
    @ObservedObject var parentViewModel: WorkerDetailViewModel
    let scriptName: String
    let modules: [WorkerModuleItem]
    let singleScriptContent: String
    
    @State private var selectedModule: WorkerModuleItem?
    @State private var currentCode: String = ""
    @State private var isEditing = false
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
                    HStack(spacing: 8) {
                        ForEach(modules) { module in
                            Button {
                                selectedModule = module
                                currentCode = module.code
                                HIGFeedback.selection()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: module.isMain ? "star.fill" : "doc.text")
                                        .font(.caption2)
                                    Text(module.name)
                                        .font(.caption.monospaced())
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedModule?.id == module.id ? Color.accentColor : Color(.secondarySystemFill))
                                .foregroundStyle(selectedModule?.id == module.id ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
                
                Divider()
            }
            
            TextEditor(text: $currentCode)
                .font(.caption.monospaced())
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
                .padding(8)
        }
        .navigationTitle(scriptName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = currentCode
                        HIGFeedback.success()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .accessibilityLabel("Copy Code")
                    
                    Button {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await parentViewModel.deployScript(
                                    code: currentCode,
                                    isModule: !modules.isEmpty
                                )
                                HIGFeedback.success()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
}
