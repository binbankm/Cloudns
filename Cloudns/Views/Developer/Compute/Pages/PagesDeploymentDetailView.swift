import SwiftUI

// MARK: - PagesDeploymentDetailView
// Apple HIG Compliant Pages Deployment Inspector & Build Terminal Logs

struct PagesDeploymentDetailView: View {
    let accountId: String
    let projectName: String
    let deployment: PagesDeployment
    @ObservedObject var parentViewModel: PagesProjectDetailViewModel
    
    @StateObject private var viewModel: PagesDeploymentDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingRollbackAlert = false
    @State private var showingDeleteAlert = false
    @State private var isActionRunning = false
    
    init(accountId: String, projectName: String, deployment: PagesDeployment, parentViewModel: PagesProjectDetailViewModel) {
        self.accountId = accountId
        self.projectName = projectName
        self.deployment = deployment
        self.parentViewModel = parentViewModel
        _viewModel = StateObject(wrappedValue: PagesDeploymentDetailViewModel(accountId: accountId, projectName: projectName, deployment: deployment))
    }
    
    var isSuccess: Bool { deployment.latestStage?.status == "success" }
    
    var body: some View {
        List {
            // MARK: - Overview
            Section(header: Text("Deployment Overview")) {
                LabeledContent {
                    let status = deployment.latestStage?.status?.capitalized ?? (isSuccess ? "Success" : "Pending")
                    Text(status)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isSuccess ? .green : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill((isSuccess ? Color.green : Color.orange).opacity(0.12)))
                } label: {
                    Text("Status")
                }
                
                if let env = deployment.environment {
                    LabeledContent("Environment", value: env.capitalized)
                }
                
                if let branch = deployment.deploymentTrigger?.metadata?.branch {
                    LabeledContent("Branch", value: branch)
                }
                
                if let hash = deployment.deploymentTrigger?.metadata?.commitHash {
                    LabeledContent {
                        Text(String(hash.prefix(7)))
                            .font(.body.monospacedDigit())
                    } label: {
                        Text("Commit")
                    }
                }
                
                if let msg = deployment.deploymentTrigger?.metadata?.commitMessage, !msg.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Commit Message")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(msg)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 2)
                }
                
                if let urlStr = deployment.url, let url = URL(string: urlStr) {
                    Link(destination: url) {
                        HStack {
                            Text("Preview URL")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(urlStr)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(Color.accentColor)
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // MARK: - Actions
            Section(header: Text("Actions")) {
                Button {
                    HapticManager.impact(.medium)
                    showingRollbackAlert = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Rollback / Promote to Production")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isActionRunning)
                
                Button {
                    HapticManager.impact(.medium)
                    Task {
                        isActionRunning = true
                        do {
                            try await parentViewModel.retryDeployment(id: deployment.id)
                            ToastManager.shared.showSuccess("Deployment Retried", icon: "arrow.clockwise")
                            HapticManager.notification(.success)
                            dismiss()
                        } catch {
                            ToastManager.shared.showError("Failed to Retry Deployment")
                            HapticManager.notification(.error)
                        }
                        isActionRunning = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.orange)
                        Text("Retry Deployment")
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isActionRunning)
                
                Button(role: .destructive) {
                    HapticManager.impact(.medium)
                    showingDeleteAlert = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                        Text("Delete Deployment")
                            .font(.body)
                            .foregroundStyle(.red)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isActionRunning)
            }
            
            // MARK: - Build Logs Section
            Section(
                header: HStack {
                    Text("Build & Execution Output")
                    Spacer()
                    if !viewModel.logs.isEmpty {
                        Text("\(viewModel.logs.count) lines")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                },
                footer: Text("Inspect real-time build stages, package installations, and Pages Functions compilation logs.")
            ) {
                terminalLogsCard
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Deployment Details")
        .navigationBarTitleDisplayMode(.inline)
        .presentationDragIndicator(.visible)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            await viewModel.fetchLogs()
        }
        .confirmationDialog("Rollback to this Deployment?", isPresented: $showingRollbackAlert, titleVisibility: .visible) {
            Button("Rollback", role: .destructive) {
                Task {
                    isActionRunning = true
                    do {
                        try await parentViewModel.rollbackDeployment(id: deployment.id)
                        ToastManager.shared.showSuccess("Rolled Back to Deployment", icon: "arrow.counterclockwise")
                        HapticManager.notification(.success)
                        dismiss()
                    } catch {
                        ToastManager.shared.showError("Failed to Roll Back")
                        HapticManager.notification(.error)
                    }
                    isActionRunning = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will immediately switch your production Pages traffic to this historical deployment build.")
        }
        .confirmationDialog("Delete Deployment?", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    isActionRunning = true
                    do {
                        try await parentViewModel.deleteDeployment(id: deployment.id)
                        ToastManager.shared.showSuccess("Deployment Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        dismiss()
                    } catch {
                        ToastManager.shared.showError("Failed to Delete")
                        HapticManager.notification(.error)
                    }
                    isActionRunning = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this deployment? This action cannot be undone.")
        }
    }
    
    // MARK: - Contained Terminal Logs Card
    
    @State private var logSearchQuery: String = ""
    
    private var filteredLogs: [PagesDeploymentLog] {
        if logSearchQuery.isEmpty { return viewModel.logs }
        return viewModel.logs.filter { $0.line.localizedStandardContains(logSearchQuery) }
    }
    
    private var allLogsString: String {
        viewModel.logs.map(\.line).joined(separator: "\n")
    }
    
    @ViewBuilder
    private var terminalLogsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search / Filter sub-bar (if logs exist)
            if !viewModel.logs.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    TextField("Filter build logs…", text: $logSearchQuery)
                        .font(.caption)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    if !logSearchQuery.isEmpty {
                        Button {
                            logSearchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        copyToClipboard(allLogsString, toast: "All Logs Copied")
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption2.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                Divider()
            }
            
            // Vertically scrollable console with natural text wrapping
            if viewModel.isLoadingLogs {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                    Text("Loading build logs from Cloudflare edge…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else if viewModel.logs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.line.magnify")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No logs recorded for this deployment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else if filteredLogs.isEmpty && !logSearchQuery.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No log lines matching '\(logSearchQuery)'")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(filteredLogs.enumerated()), id: \.element.id) { idx, log in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(idx + 1)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .frame(width: 24, alignment: .trailing)
                                
                                Text(log.line)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(logColor(log.line))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 280)
                .textSelection(.enabled)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
    
    private func logColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error") || lower.contains("failed") || lower.contains("fatal") || lower.contains("exception") {
            return .red
        } else if lower.contains("warn") {
            return .orange
        } else if lower.contains("success") || lower.contains("complete") || lower.contains("published") || lower.contains("ready") {
            return .green
        } else if lower.contains("info") || lower.contains("building") || lower.contains("deploying") {
            return .blue
        }
        return .primary
    }
}
