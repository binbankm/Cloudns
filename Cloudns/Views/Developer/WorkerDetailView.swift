import SwiftUI
import UniformTypeIdentifiers

struct WorkerDetailView: View {
    let accountId: String
    let worker: WorkerScript
    @StateObject private var viewModel: WorkerDetailViewModel
    
    init(accountId: String, worker: WorkerScript) {
        self.accountId = accountId
        self.worker = worker
        _viewModel = StateObject(wrappedValue: WorkerDetailViewModel(accountId: accountId, worker: worker))
    }
    
    var body: some View {
        contentView
            .navigationTitle(worker.id)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.fetchDetails()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchDetails()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section(header: Text("Script Overview")) {
                    HStack {
                        Text("Script Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("my-worker")
                    }
                    .skeletonLoading(true)
                    
                    HStack {
                        Text("Total Size")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("12.4 KB")
                    }
                    .skeletonLoading(true)
                }
            } else {
                // Section: Metadata
                Section(header: Text("Script Overview")) {
                    HStack {
                        Text("Script Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(viewModel.worker.id)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
                    if let sub = viewModel.subdomain {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("workers.dev Subdomain")
                                    .foregroundStyle(.primary)
                                if sub.enabled, let id = sub.id {
                                    Text("https://\(id)")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { sub.enabled },
                                set: { val in
                                    Task { await viewModel.toggleSubdomain(enabled: val) }
                                }
                            ))
                            .disabled(viewModel.isSubdomainUpdating)
                        }
                    }
                    
                    if !viewModel.modules.isEmpty {
                        HStack {
                            Text("Modules")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.modules.count > 1 ? "\(viewModel.modules.count) Modules (ESM)" : "1 Module")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if !viewModel.scriptContent.isEmpty {
                        HStack {
                            Text("Total Size")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatBytes(viewModel.scriptContent.utf8.count))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if let usage = viewModel.worker.usageModel {
                        HStack {
                            Text("Usage Model")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(usage.capitalized)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if let compat = viewModel.worker.compatibilityDate {
                        HStack {
                            Text("Compatibility Date")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(compat)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if let modified = viewModel.worker.modifiedOn {
                        HStack {
                            Text("Last Modified")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(DateFormatters.formatISO8601ToDisplay(modified))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                // Section: Management Links
                Section(header: Text("Management")) {
                    NavigationLink {
                        WorkerSourceCodeView(
                            parentViewModel: viewModel,
                            scriptName: worker.id,
                            modules: viewModel.modules,
                            singleScriptContent: viewModel.scriptContent
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "curlybraces")
                                .font(.body)
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text("Source Code")
                                .foregroundStyle(.primary)
                            Spacer()
                            if !viewModel.scriptContent.isEmpty {
                                Text(formatBytes(viewModel.scriptContent.utf8.count))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        WorkerRoutesView(accountId: accountId, scriptName: worker.id, fallbackRoutes: worker.routes ?? [])
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.body)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text("Domains & Routes")
                                .foregroundStyle(.primary)
                            Spacer()
                            if let routes = worker.routes, !routes.isEmpty {
                                Text("\(routes.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        WorkerSecretsView(accountId: accountId, scriptName: worker.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.body)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text("Variables & Secrets")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                    
                    NavigationLink {
                        WorkerTriggersView(accountId: accountId, scriptName: worker.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.body)
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text("Cron Triggers")
                                .foregroundStyle(.primary)
                            Spacer()
                            if !viewModel.schedules.isEmpty {
                                Text("\(viewModel.schedules.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        WorkerTailView(accountId: accountId, scriptName: worker.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.body)
                                .foregroundStyle(.green)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text("Real-Time Logs")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
                
                // Section: Debugging
                Section(header: Text("Debugging")) {
                    NavigationLink {
                        WorkerTestView(scriptName: worker.id, initialRoute: worker.routes?.first)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "paperplane.fill")
                                .font(.body)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text("Test Dispatch")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
                
                // Section: Resource Bindings
                Section(header: Text("Resource Bindings (\(viewModel.bindings.count))")) {
                    if viewModel.bindings.isEmpty {
                        Text("No KV, R2, D1 or secret bindings configured.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.bindings) { binding in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(binding.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    if let extra = binding.namespaceId ?? binding.bucketName ?? binding.databaseId {
                                        Text(extra)
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(binding.type.uppercased())
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.2f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
}

// MARK: - Dedicated Worker Source Code View (Standalone Page)
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
    
    init(parentViewModel: WorkerDetailViewModel, scriptName: String, modules: [WorkerModuleItem], singleScriptContent: String) {
        self.parentViewModel = parentViewModel
        self.scriptName = scriptName
        self.modules = modules
        self.singleScriptContent = singleScriptContent
        
        let initialName = modules.first(where: { $0.isMain })?.name ?? modules.first?.name ?? "index.js"
        _selectedModuleName = State(initialValue: initialName)
    }
    
    private var currentCode: String {
        if !modules.isEmpty {
            return modules.first(where: { $0.name == selectedModuleName })?.code ?? singleScriptContent
        }
        return singleScriptContent
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
