import SwiftUI
import UniformTypeIdentifiers

// MARK: - WorkerSourceCodeView

struct WorkerSourceCodeView: View {
    // MARK: - Properties
    @ObservedObject var parentViewModel: WorkerDetailViewModel
    let scriptName: String
    let modules: [WorkerModuleItem]
    let singleScriptContent: String
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedModuleName: String = "index.js"
    @State private var editableCode: String = ""
    @State private var isEditingMode: Bool = false
    @State private var isDeploying: Bool = false
    @State private var showingDeployAlert: Bool = false
    @State private var wrapLines: Bool = true
    @State private var fontSize: CGFloat = 13.0
    
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
        let liveModules = parentViewModel.modules.isEmpty ? modules : parentViewModel.modules
        let liveContent = parentViewModel.scriptContent.isEmpty ? singleScriptContent : parentViewModel.scriptContent
        
        if !liveModules.isEmpty {
            return liveModules.first(where: { $0.name == selectedModuleName })?.code ?? liveContent
        }
        return liveContent
    }
    
    private var activeModules: [WorkerModuleItem] {
        parentViewModel.modules.isEmpty ? modules : parentViewModel.modules
    }
    
    private var isESMModule: Bool {
        editableCode.contains("export default") || editableCode.contains("export {") || editableCode.contains("export const") || editableCode.contains("export function")
    }
    
    private var lineCount: Int {
        editableCode.components(separatedBy: "\n").count
    }
    
    private var byteCount: Int {
        editableCode.utf8.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Top Tab Bar: Modules (if multi-module)
            if activeModules.count > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(activeModules) { mod in
                            Button {
                                HapticManager.impact(.light)
                                selectedModuleName = mod.name
                                editableCode = mod.code
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: mod.isMain ? "star.fill" : "doc.text")
                                        .font(.caption2)
                                        .foregroundStyle(selectedModuleName == mod.name ? Color.orange : Color.secondary)
                                        .accessibilityHidden(true)
                                    Text(mod.name)
                                        .font(.subheadline.weight(selectedModuleName == mod.name ? .semibold : .regular))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedModuleName == mod.name ? Color.orange.opacity(0.15) : Color(.tertiarySystemFill))
                                .foregroundStyle(selectedModuleName == mod.name ? Color.orange : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CloudnsRadius.sm)
                                        .stroke(selectedModuleName == mod.name ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .background(CloudnsColor.groupedBackground)
                Divider()
            }
            
            // 2. Control Toolbar (Font scaling + Line Wrap + Mode Switcher)
            controlBar
            
            Divider()
            
            // 3. Native Syntax-Highlighted Code View
            CloudnsCodeEditorView(
                text: $editableCode,
                isEditable: isEditingMode,
                wrapLines: wrapLines,
                fontSize: fontSize,
                isDarkMode: colorScheme == .dark
            )
            .id("\(selectedModuleName)-\(wrapLines)-\(fontSize)")
            .background(CloudnsColor.secondaryGroupedBackground)
            
            Divider()
            
            // 4. Bottom Status & Metadata Bar
            statusBar
        }
        .navigationTitle(selectedModuleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
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
                    CloudnsToastManager.shared.showCopied("Source code copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.subheadline)
                }
                .accessibilityLabel("Copy Code")
            }
        }
        .onAppear {
            let liveModules = activeModules
            let liveContent = parentViewModel.scriptContent.isEmpty ? singleScriptContent : parentViewModel.scriptContent
            
            if !liveModules.isEmpty && !liveModules.contains(where: { $0.name == selectedModuleName }) {
                selectedModuleName = liveModules.first(where: { $0.isMain })?.name ?? liveModules.first?.name ?? selectedModuleName
            }
            editableCode = currentCode
            
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
                        let isServiceWorker = editableCode.contains("addEventListener") || editableCode.contains("respondWith")
                        let resolvedIsModule = isESMModule || !isServiceWorker
                        
                        try await parentViewModel.deployScript(code: editableCode, isModule: resolvedIsModule)
                        HapticManager.notification(.success)
                        CloudnsToastManager.shared.showSuccess("Script Deployed", message: "Worker updated successfully")
                        isEditingMode = false
                    } catch {
                        CloudnsToastManager.shared.showError("Deploy Failed", message: error.localizedDescription)
                    }
                    isDeploying = false
                }
            }
        } message: {
            Text("This will immediately deploy the modified code to '\(scriptName)' while safely preserving all resource bindings and secrets.")
        }
    }
    
    // MARK: - Control Bar
    @ViewBuilder
    private var controlBar: some View {
        HStack(spacing: 12) {
            // Font Size Controls [A-] [A+]
            HStack(spacing: 2) {
                Button {
                    HapticManager.selection()
                    if fontSize > 10.0 {
                        fontSize -= 1.0
                    }
                } label: {
                    Text("A-")
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 26)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .disabled(fontSize <= 10.0)
                
                Button {
                    HapticManager.selection()
                    if fontSize < 20.0 {
                        fontSize += 1.0
                    }
                } label: {
                    Text("A+")
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 26)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .disabled(fontSize >= 20.0)
            }
            
            // Word Wrap Toggle
            Button {
                HapticManager.selection()
                withAnimation(.easeInOut(duration: 0.15)) {
                    wrapLines.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: wrapLines ? "text.word.spacing" : "arrow.left.and.right")
                        .font(.caption2)
                    Text(wrapLines ? "Wrap" : "Scroll")
                        .font(.caption2.weight(.medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(wrapLines ? Color.orange.opacity(0.12) : Color(.tertiarySystemFill))
                .foregroundStyle(wrapLines ? Color.orange : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Read-Only / Edit Toggle
            HStack(spacing: 0) {
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditingMode = false
                    }
                } label: {
                    let isActive = !isEditingMode
                    Text("Read Only")
                        .font(.caption2.weight(isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? Color.primary : Color.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isActive ? Color(.systemBackground) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
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
                        .font(.caption2.weight(isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? Color.primary : Color.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isActive ? Color(.systemBackground) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            }
            .padding(2)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            if isEditingMode {
                Button {
                    HapticManager.impact(.medium)
                    showingDeployAlert = true
                } label: {
                    HStack(spacing: 4) {
                        if isDeploying {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Deploy")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(isDeploying || editableCode.isEmpty)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(CloudnsColor.secondaryGroupedBackground)
    }
    
    // MARK: - Status Bar
    @ViewBuilder
    private var statusBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Circle()
                    .fill(isESMModule ? Color.purple : Color.orange)
                    .frame(width: 6, height: 6)
                Text(isESMModule ? "ES Module" : "Service Worker")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
            }
            
            Text("•")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text("\(lineCount) Lines")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            
            Text("•")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(formatBytes(byteCount))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("UTF-8")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(CloudnsColor.groupedBackground)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        ByteCountFormatters.format(Int64(bytes))
    }
}
