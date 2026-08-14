import SwiftUI
import UniformTypeIdentifiers

struct WorkerDetailView: View {
    let accountId: String
    let worker: WorkerScript
    @StateObject private var viewModel: WorkerDetailViewModel
    @State private var showingCodeFullscreen = false
    
    init(accountId: String, worker: WorkerScript) {
        self.accountId = accountId
        self.worker = worker
        _viewModel = StateObject(wrappedValue: WorkerDetailViewModel(accountId: accountId, worker: worker))
    }
    
    var body: some View {
        contentView
            .navigationTitle(worker.id)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCodeFullscreen) {
                WorkerSourceCodeViewerSheet(
                    accountId: accountId,
                    scriptName: worker.id,
                    modules: viewModel.modules,
                    initialSelectedModuleName: viewModel.selectedModule?.name,
                    parentViewModel: viewModel
                )
            }
            .refreshable {
                await viewModel.fetchDetails()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchDetails()
                }
            }
            .toastContainer()
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
            } else {
                // Section: Metadata
                Section(header: Text("Script Overview")) {
                    HStack {
                        Text("Script Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(worker.id)
                            .font(.body.monospaced())
                            .foregroundColor(.primary)
                    }
                    
                    if let sub = viewModel.subdomain {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("workers.dev Subdomain")
                                    .foregroundColor(.primary)
                                if sub.enabled, let id = sub.id {
                                    Text("https://\(id)")
                                        .font(.caption2.monospaced())
                                        .foregroundColor(.secondary)
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
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(viewModel.modules.count > 1 ? "\(viewModel.modules.count) Modules (ESM)" : "1 Module")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if !viewModel.scriptContent.isEmpty {
                        HStack {
                            Text("Total Size")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatBytes(viewModel.scriptContent.utf8.count))
                                .font(.body.monospaced())
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let usage = worker.usageModel {
                        HStack {
                            Text("Usage Model")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(usage.capitalized)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let compat = worker.compatibilityDate {
                        HStack {
                            Text("Compatibility Date")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(compat)
                                .font(.body.monospaced())
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let modified = worker.modifiedOn {
                        HStack {
                            Text("Last Modified")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(modified.prefix(19)).replacingOccurrences(of: "T", with: " "))
                                .font(.body.monospaced())
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Section: Script Source Code Preview
                Section(header: HStack {
                    Text("Source Code")
                    Spacer()
                    if let currentMod = viewModel.selectedModule ?? viewModel.modules.first {
                        Button {
                            UIPasteboard.general.string = currentMod.code
                            ToastManager.shared.showCopied("\(currentMod.name) copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                    }
                }) {
                    if viewModel.modules.isEmpty && viewModel.scriptContent.isEmpty {
                        Text(viewModel.errorMessage ?? "No script source code available.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            // Module tabs if multi-module
                            if viewModel.modules.count > 1 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(viewModel.modules) { mod in
                                            Button {
                                                viewModel.selectModule(mod)
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: mod.isMain ? "star.fill" : "doc.text")
                                                        .font(.system(size: 10))
                                                    Text(mod.name)
                                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(viewModel.selectedModule?.name == mod.name ? Color.orange : Color(UIColor.tertiarySystemFill))
                                                .foregroundColor(viewModel.selectedModule?.name == mod.name ? .white : .primary)
                                                .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            
                            let codeToShow = viewModel.selectedModule?.code ?? viewModel.scriptContent
                            let previewText = String(codeToShow.prefix(800)) + (codeToShow.count > 800 ? "\n..." : "")
                            
                            Text(previewText)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                            
                            Button {
                                showingCodeFullscreen = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Label(
                                        "View & Edit Code (\(formatBytes(codeToShow.utf8.count)))",
                                        systemImage: "curlybraces"
                                    )
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.orange)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Section: Management Links
                Section(header: Text("Management")) {
                    NavigationLink {
                        WorkerRoutesView(accountId: accountId, scriptName: worker.id, fallbackRoutes: worker.routes ?? [])
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Domains & Routes")
                                .foregroundColor(.primary)
                            Spacer()
                            if let routes = worker.routes, !routes.isEmpty {
                                Text("\(routes.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        WorkerSecretsView(accountId: accountId, scriptName: worker.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.body)
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Environment Secrets")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    NavigationLink {
                        WorkerTriggersView(accountId: accountId, scriptName: worker.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.body)
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Cron Triggers")
                                .foregroundColor(.primary)
                            Spacer()
                            if !viewModel.schedules.isEmpty {
                                Text("\(viewModel.schedules.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Section: Debugging
                Section(header: Text("Debugging")) {
                    NavigationLink {
                        WorkerTailView(accountId: accountId, scriptName: worker.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "terminal.fill")
                                .font(.body)
                                .foregroundColor(.green)
                                .frame(width: 24)
                            Text("Live Tail Logs")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    NavigationLink {
                        WorkerTestView(scriptName: worker.id, initialRoute: worker.routes?.first)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "paperplane.fill")
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Test Dispatch")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                
                // Section: Resource Bindings
                Section(header: Text("Resource Bindings (\(viewModel.bindings.count))")) {
                    if viewModel.bindings.isEmpty {
                        Text("No KV, R2, D1 or secret bindings configured.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.bindings) { binding in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(binding.name)
                                        .font(.body.monospaced())
                                        .foregroundColor(.primary)
                                    
                                    if let extra = binding.namespaceId ?? binding.bucketName ?? binding.databaseId {
                                        Text(extra)
                                            .font(.caption2.monospaced())
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(binding.type.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
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

// MARK: - Orange-Cloud Style Code Viewer & Editor Sheet

struct WorkerSourceCodeViewerSheet: View {
    let accountId: String
    let scriptName: String
    let modules: [WorkerModuleItem]
    @ObservedObject var parentViewModel: WorkerDetailViewModel
    
    @State private var selectedModuleName: String
    @State private var isEditingMode = false
    @State private var editableCode: String = ""
    @State private var wrapLines = true
    @State private var isDeploying = false
    @State private var showingDeployAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(accountId: String, scriptName: String, modules: [WorkerModuleItem], initialSelectedModuleName: String? = nil, parentViewModel: WorkerDetailViewModel) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.modules = modules
        self.parentViewModel = parentViewModel
        let initial = initialSelectedModuleName ?? modules.first(where: { $0.isMain })?.name ?? modules.first?.name ?? "index.js"
        _selectedModuleName = State(initialValue: initial)
    }
    
    private var currentModule: WorkerModuleItem? {
        modules.first(where: { $0.name == selectedModuleName }) ?? modules.first
    }
    
    private var currentCode: String {
        currentModule?.code ?? parentViewModel.scriptContent
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Tab Bar: Modules (if multi-module)
                if modules.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(modules) { mod in
                                Button {
                                    selectedModuleName = mod.name
                                    editableCode = mod.code
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: mod.isMain ? "star.fill" : "doc.text")
                                            .font(.system(size: 11))
                                        Text(mod.name)
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedModuleName == mod.name ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
                                    .foregroundColor(selectedModuleName == mod.name ? .white : .primary)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                    Divider()
                }
                
                // Mode switcher bar (View / Edit)
                HStack {
                    HStack(spacing: 0) {
                        Button {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditingMode = false
                            }
                        } label: {
                            Text("View Code")
                                .font(.system(size: 13, weight: isEditingMode ? .regular : .semibold))
                                .foregroundColor(isEditingMode ? .secondary : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(isEditingMode ? Color.clear : Color(UIColor.systemBackground))
                                .cornerRadius(6)
                                .shadow(color: isEditingMode ? .clear : Color.black.opacity(0.08), radius: 2, y: 1)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditingMode = true
                            }
                        } label: {
                            Text("Edit & Deploy")
                                .font(.system(size: 13, weight: isEditingMode ? .semibold : .regular))
                                .foregroundColor(isEditingMode ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(isEditingMode ? Color(UIColor.systemBackground) : Color.clear)
                                .cornerRadius(6)
                                .shadow(color: isEditingMode ? Color.black.opacity(0.08) : .clear, radius: 2, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(3)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(8)
                    .frame(maxWidth: 220)
                    
                    Spacer()
                    
                    if isEditingMode {
                        Button {
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
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .disabled(isDeploying || editableCode.isEmpty)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                Divider()
                
                // Native High-Performance Code View / Editor with zero lag
                CodeEditorView(
                    text: $editableCode,
                    isEditable: isEditingMode,
                    wrapLines: wrapLines
                )
                .id("\(selectedModuleName)-\(wrapLines)")
                .background(Color(UIColor.secondarySystemGroupedBackground))
            }
            .navigationTitle(selectedModuleName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        wrapLines.toggle()
                    } label: {
                        Image(systemName: wrapLines ? "text.word.spacing" : "arrow.left.and.right")
                            .font(.subheadline)
                            .foregroundColor(wrapLines ? .accentColor : .secondary)
                    }
                    
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
                        ToastManager.shared.showCopied("Source code copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline)
                    }
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
                            try await parentViewModel.deployScript(code: editableCode, isModule: true)
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
            .toastContainer()
        }
    }
}

