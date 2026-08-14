import SwiftUI

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
            // Section 1: Overview
            Section(header: Text("Deployment Overview")) {
                HStack {
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isSuccess ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(deployment.latestStage?.status?.capitalized ?? "Unknown")
                            .font(.body.weight(.semibold))
                            .foregroundColor(isSuccess ? .green : .orange)
                    }
                }
                
                if let env = deployment.environment {
                    HStack {
                        Text("Environment")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(env.capitalized)
                            .foregroundColor(.primary)
                    }
                }
                
                if let branch = deployment.deploymentTrigger?.metadata?.branch {
                    HStack {
                        Text("Branch")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(branch)
                            .font(.body.monospaced())
                            .foregroundColor(.primary)
                    }
                }
                
                if let hash = deployment.deploymentTrigger?.metadata?.commitHash {
                    HStack {
                        Text("Commit")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(hash.prefix(7)))
                            .font(.body.monospaced())
                            .foregroundColor(.primary)
                    }
                }
                
                if let msg = deployment.deploymentTrigger?.metadata?.commitMessage, !msg.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Commit Message")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(msg)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 2)
                }
                
                if let urlStr = deployment.url, let url = URL(string: urlStr) {
                    Link(destination: url) {
                        HStack {
                            Text("Preview URL")
                            Spacer()
                            Text(urlStr)
                                .font(.caption.monospaced())
                                .lineLimit(1)
                                .foregroundColor(.blue)
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Section 2: Actions
            Section(header: Text("Actions")) {
                Button {
                    showingRollbackAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundColor(.blue)
                        Text("Rollback / Promote to Production")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isActionRunning)
                
                Button {
                    Task {
                        isActionRunning = true
                        do {
                            try await parentViewModel.retryDeployment(id: deployment.id)
                            ToastManager.shared.showSuccess("Deployment Retried", message: "Build queued")
                            dismiss()
                        } catch {
                            ToastManager.shared.showError("Retry Failed", message: error.localizedDescription)
                        }
                        isActionRunning = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                        Text("Retry Deployment")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isActionRunning)
                
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Delete Deployment")
                            .foregroundColor(.red)
                    }
                }
                .disabled(isActionRunning)
            }
            
            // Section 3: Build Logs
            Section(header: Text("Build Logs (\(viewModel.logs.count) lines)")) {
                if viewModel.isLoadingLogs {
                    HStack {
                        Spacer()
                        ProgressView("Loading logs…")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else if viewModel.logs.isEmpty {
                    Text("No build logs available for this deployment.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(viewModel.logs) { log in
                                Text(log.line)
                                    .font(.caption2.monospaced())
                                    .foregroundColor(logColor(log.line))
                            }
                        }
                        .padding(8)
                        .background(Color(UIColor.black))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .navigationTitle("Deployment Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            await viewModel.fetchLogs()
        }
        .alert("Rollback to this Deployment?", isPresented: $showingRollbackAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Rollback", role: .destructive) {
                Task {
                    isActionRunning = true
                    do {
                        try await parentViewModel.rollbackDeployment(id: deployment.id)
                        ToastManager.shared.showSuccess("Rolled Back", message: "Promoted to production")
                        dismiss()
                    } catch {
                        ToastManager.shared.showError("Rollback Failed", message: error.localizedDescription)
                    }
                    isActionRunning = false
                }
            }
        } message: {
            Text("This will immediately switch your production Pages traffic to this historical deployment build.")
        }
        .alert("Delete Deployment?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    isActionRunning = true
                    do {
                        try await parentViewModel.deleteDeployment(id: deployment.id)
                        ToastManager.shared.showSuccess("Deployment Deleted", message: deployment.id)
                        dismiss()
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                    isActionRunning = false
                }
            }
        } message: {
            Text("Are you sure you want to delete this deployment? This action cannot be undone.")
        }
        .toastContainer()
    }
    
    private func logColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error") || lower.contains("failed") || lower.contains("fatal") {
            return .red
        } else if lower.contains("warn") {
            return .orange
        } else if lower.contains("success") || lower.contains("complete") {
            return .green
        }
        return .white.opacity(0.85)
    }
}
