import SwiftUI

struct PagesDeploymentDetailView: View {
    // MARK: - Properties
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
    
    // MARK: - Body
    var body: some View {
        List {
            // MARK: - Overview
            Section(header: Text("Deployment Overview")) {
                HStack {
                    Text("Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    CloudnsBadge(isSuccess ? .active(deployment.latestStage?.status?.capitalized ?? "Success") : .warning(deployment.latestStage?.status?.capitalized ?? "Pending"), isCompact: true)
                }
                
                if let env = deployment.environment {
                    HStack {
                        Text("Environment")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(env.capitalized)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let branch = deployment.deploymentTrigger?.metadata?.branch {
                    HStack {
                        Text("Branch")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(branch)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let hash = deployment.deploymentTrigger?.metadata?.commitHash {
                    HStack {
                        Text("Commit")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(hash.prefix(7)))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
                
                if let msg = deployment.deploymentTrigger?.metadata?.commitMessage, !msg.isEmpty {
                    VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                        Text("Commit Message")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(msg)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, CloudnsSpacing.xxs)
                }
                
                if let urlStr = deployment.url, let url = URL(string: urlStr) {
                    Link(destination: url) {
                        HStack {
                            Text("Preview URL")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(urlStr)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.blue)
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
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Rollback / Promote to Production")
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
                            CloudnsToastManager.shared.showSuccess("Deployment Retried", message: "Build queued")
                            dismiss()
                        } catch {
                            CloudnsToastManager.shared.showError("Retry Failed", message: error.localizedDescription)
                        }
                        isActionRunning = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.orange)
                        Text("Retry Deployment")
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isActionRunning)
                
                Button(role: .destructive) {
                    HapticManager.impact(.medium)
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                        Text("Delete Deployment")
                            .foregroundStyle(.red)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isActionRunning)
            }
            
            // MARK: - Build Logs
            Section(header: Text("Build Logs (\(viewModel.logs.count) lines)")) {
                if viewModel.isLoadingLogs {
                    VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                        ForEach(0..<4, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: CloudnsRadius.xs)
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 10)
                                .frame(maxWidth: idx == 3 ? 180 : .infinity)
                        }
                    }
                    .padding(CloudnsSpacing.smMd)
                    .background(Color.black.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                    .skeletonLoading(true)
                } else if viewModel.logs.isEmpty {
                    Text("No build logs available for this deployment.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                            ForEach(viewModel.logs) { log in
                                Text(log.line)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(logColor(log.line))
                            }
                        }
                        .padding(CloudnsSpacing.sm)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
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
                        CloudnsToastManager.shared.showSuccess("Rolled Back", message: "Promoted to production")
                        dismiss()
                    } catch {
                        CloudnsToastManager.shared.showError("Rollback Failed", message: error.localizedDescription)
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
                        CloudnsToastManager.shared.showSuccess("Deployment Deleted", message: deployment.id)
                        dismiss()
                    } catch {
                        CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                    isActionRunning = false
                }
            }
        } message: {
            Text("Are you sure you want to delete this deployment? This action cannot be undone.")
        }
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
