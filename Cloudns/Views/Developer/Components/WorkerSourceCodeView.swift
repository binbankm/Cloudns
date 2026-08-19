import SwiftUI
import UniformTypeIdentifiers

// MARK: - WorkerSourceCodeView

struct WorkerSourceCodeView: View {
    @ObservedObject var parentViewModel: WorkerDetailViewModel
    let scriptName: String
    let modules: [WorkerModuleItem]
    let singleScriptContent: String
    
    @State private var selectedModuleName: String = "index.js"
    @State private var editableCode: String = ""
    @State private var isEditingMode: Bool = false
    @State private var isDeploying: Bool = false
    @State private var showingDeployAlert: Bool = false
    @State private var wrapLines: Bool = true
    
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
        
        let initialName = modules.first(where: { $0.isMain })?.name ?? modules.first?.name ?? "index.js"
        _selectedModuleName = State(initialValue: initialName)
    }
    
    private var currentCode: String {
        // Prefer live data from parentViewModel over the init-time snapshot
        let liveModules = parentViewModel.modules.isEmpty ? modules : parentViewModel.modules
        let liveContent = parentViewModel.scriptContent.isEmpty ? singleScriptContent : parentViewModel.scriptContent
        
        if !liveModules.isEmpty {
            return liveModules.first(where: { $0.name == selectedModuleName })?.code ?? liveContent
        }
        return liveContent
    }
    
    @ViewBuilder
    private var modeSwitcherBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditingMode = false
                    }
                } label: {
                    let isActive = !isEditingMode
                    Text("Read Only")
                        .font(.footnote.weight(isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isActive ? Color(.systemBackground) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditingMode = true
                    }
                } label: {
                    let isActive = isEditingMode
                    Text("Edit")
                        .font(.footnote.weight(isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isActive ? Color(.systemBackground) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(3)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 160)
            
            Spacer()
            
            if isEditingMode {
                Button {
                    HapticManager.impact(.medium)
                    showingDeployAlert = true
                } label: {
                    HStack(spacing: 4) {
                        if isDeploying {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Deploy")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isDeploying || editableCode.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Tab Bar: Modules (if multi-module)
            if modules.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(modules) { mod in
                            Button {
                                HapticManager.impact(.light)
                                selectedModuleName = mod.name
                                editableCode = mod.code
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: mod.isMain ? "star.fill" : "doc.text")
                                        .font(.caption2)
                                        .accessibilityHidden(true)
                                    Text(mod.name)
                                        .font(.body)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedModuleName == mod.name ? Color.orange : Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(selectedModuleName == mod.name ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))
                Divider()
            }
            
            // Mode switcher bar (View / Edit)
            modeSwitcherBar
            
            Divider()
            
            // Native High-Performance Code View / Editor
            CodeEditorView(
                text: $editableCode,
                isEditable: isEditingMode,
                wrapLines: wrapLines
            )
            .id("\(selectedModuleName)-\(wrapLines)")
            .background(Color(.secondarySystemGroupedBackground))
        }
        .navigationTitle(selectedModuleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.selection()
                    wrapLines.toggle()
                } label: {
                    Image(systemName: wrapLines ? "text.word.spacing" : "arrow.left.and.right")
                        .font(.subheadline)
                        .foregroundStyle(wrapLines ? Color.accentColor : Color.secondary)
                }
                .accessibilityLabel("Toggle Line Wrap")
                
                ShareLink(
                    item: editableCode,
                    subject: Text(selectedModuleName),
                    message: Text("Worker script exported from Cloudns")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                }
                
                Button {
                    UIPasteboard.general.string = editableCode
                    HapticManager.notification(.success)
                    ToastManager.shared.showCopied("Source code copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.subheadline)
                }
                .accessibilityLabel("Copy Code")
            }
        }
        .onAppear {
            // Use live ViewModel data if available (async fetch may have completed)
            let liveModules = parentViewModel.modules.isEmpty ? modules : parentViewModel.modules
            let liveContent = parentViewModel.scriptContent.isEmpty ? singleScriptContent : parentViewModel.scriptContent
            
            // Sync selected module name to the actual available data
            if !liveModules.isEmpty && !liveModules.contains(where: { $0.name == selectedModuleName }) {
                selectedModuleName = liveModules.first(where: { $0.isMain })?.name ?? liveModules.first?.name ?? selectedModuleName
            }
            editableCode = currentCode
            
            // If still empty, it means ViewModel hasn't loaded yet — trigger fetch
            if liveContent.isEmpty && !parentViewModel.hasFetchedData {
                Task { await parentViewModel.fetchDetails() }
            }
        }
        .onChange(of: parentViewModel.scriptContent) { newContent in
            guard !newContent.isEmpty else { return }
            editableCode = currentCode
        }
        .onChange(of: parentViewModel.modules) { newModules in
            guard !newModules.isEmpty else { return }
            if !newModules.contains(where: { $0.name == selectedModuleName }) {
                selectedModuleName = newModules.first(where: { $0.isMain })?.name ?? newModules.first?.name ?? selectedModuleName
            }
            editableCode = currentCode
        }
        .onChange(of: selectedModuleName) { _ in
            editableCode = currentCode
        }
        .alert("Deploy Updated Script?", isPresented: $showingDeployAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Deploy", role: .destructive) {
                Task {
                    isDeploying = true
                    do {
                        let hasEsm = editableCode.contains("export default") || editableCode.contains("export {") || editableCode.contains("export const") || editableCode.contains("export function")
                        let isServiceWorker = editableCode.contains("addEventListener") || editableCode.contains("respondWith")
                        let resolvedIsModule = hasEsm || !isServiceWorker
                        
                        try await parentViewModel.deployScript(code: editableCode, isModule: resolvedIsModule)
                        HapticManager.notification(.success)
                        ToastManager.shared.showSuccess("Script Deployed", message: "Worker updated successfully")
                        isEditingMode = false
                    } catch {
                        ToastManager.shared.showError("Deploy Failed", message: error.localizedDescription)
                    }
                    isDeploying = false
                }
            }
        } message: {
            Text("This will immediately deploy the modified code to '\(scriptName)' while safely preserving all resource bindings and secrets.")
        }
    }
}
