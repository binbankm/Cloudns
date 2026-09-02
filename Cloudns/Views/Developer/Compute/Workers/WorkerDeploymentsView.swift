import SwiftUI

// MARK: - WorkerDeploymentsView
// Apple HIG Compliant Cloudflare Worker Deployment Timeline & Rollback Engine

struct WorkerDeploymentsView: View {
    let accountId: String
    let scriptName: String
    @StateObject private var viewModel: WorkerDeploymentsViewModel
    @State private var deploymentToRollback: WorkerDeployment?
    @State private var showingRollbackAlert = false
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerDeploymentsViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredDeployments.isEmpty {
                Section(
                    header: Text("Deployments (\(viewModel.deployments.count))"),
                    footer: Text("Roll back to any previous deployment version to instantly restore your Worker code, routes, and environment configuration.")
                ) {
                    ForEach(Array(viewModel.filteredDeployments.enumerated()), id: \.element.id) { index, dep in
                        deploymentRow(dep, isLatest: index == 0)
                            .contextMenu {
                                if index != 0 {
                                    Button {
                                        HIGFeedback.impact(.medium)
                                        deploymentToRollback = dep
                                        showingRollbackAlert = true
                                    } label: {
                                        Label("Rollback to Version #\(dep.number ?? 1)", systemImage: "arrow.counterclockwise")
                                    }
                                }
                                
                                Button {
                                    UIPasteboard.general.string = dep.id
                                    ToastManager.shared.showCopied("Deployment ID Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Deployment ID", systemImage: "doc.on.doc")
                                }
                                
                                if let author = dep.authorEmail ?? dep.author, !author.isEmpty {
                                    Button {
                                        UIPasteboard.general.string = author
                                        ToastManager.shared.showCopied("Author Email Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Author Email", systemImage: "envelope")
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if index != 0 {
                                    Button {
                                        HIGFeedback.impact(.medium)
                                        deploymentToRollback = dep
                                        showingRollbackAlert = true
                                    } label: {
                                        Label("Rollback", systemImage: "arrow.counterclockwise")
                                    }
                                    .tint(.orange)
                                }
                                
                                Button {
                                    UIPasteboard.general.string = dep.id
                                    ToastManager.shared.showCopied("Deployment ID Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy ID", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Deployments"
        )
        .navigationTitle("Deployments")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchDeployments()
        }
        .confirmationDialog(
            "Rollback Deployment",
            isPresented: $showingRollbackAlert,
            titleVisibility: .visible,
            presenting: deploymentToRollback
        ) { dep in
            Button("Rollback to Version #\(dep.number ?? 1)", role: .destructive) {
                HIGFeedback.impact(.heavy)
                Task {
                    let success = await viewModel.rollback(deployment: dep)
                    if success {
                        ToastManager.shared.showSuccess("Rolled back to Version #\(dep.number ?? 1)", icon: "arrow.counterclockwise")
                        HIGFeedback.success()
                    } else {
                        ToastManager.shared.showError("Failed to Roll Back")
                        HIGFeedback.error()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { dep in
            Text("Are you sure you want to rollback '\(scriptName)' to Version #\(dep.number ?? 1)? Traffic will immediately be routed to this deployment version.")
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Deployments…"))
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.deployments.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchDeployments() } }
                        )
                    )
                } else if viewModel.deployments.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Deployments",
                            systemImage: "clock.arrow.circlepath",
                            description: "No deployment history found for Worker '\(scriptName)'.",
                            actionTitle: "Refresh",
                            action: { Task { await viewModel.fetchDeployments() } }
                        )
                    )
                } else if viewModel.filteredDeployments.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchDeployments()
            }
        }
    }
    
    // MARK: - Row Subview
    @ViewBuilder
    private func deploymentRow(_ dep: WorkerDeployment, isLatest: Bool) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
            // Header: Version + Status + Source
            HStack(alignment: .center, spacing: HIGTokens.Spacing.sm) {
                HStack(spacing: HIGTokens.Spacing.xxs) {
                    Image(systemName: isLatest ? "checkmark.circle.fill" : "circle.fill")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(isLatest ? HIGColors.success : .secondary)
                    
                    Text("v\(dep.number ?? 1)")
                        .font(HIGTypography.subheadline.monospacedDigit().weight(.bold))
                }
                .padding(.horizontal, HIGTokens.Spacing.sm)
                .padding(.vertical, HIGTokens.Spacing.xxs + 1)
                .background(isLatest ? HIGColors.success.opacity(0.12) : Color(.secondarySystemFill))
                .foregroundStyle(isLatest ? HIGColors.success : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.sm, style: .continuous))
                
                if isLatest {
                    HIGBadge(.active("Active"), isCompact: true)
                }
                
                Spacer()
                
                HStack(spacing: HIGTokens.Spacing.xxs) {
                    Image(systemName: sourceIcon(for: dep.source))
                        .font(HIGTypography.caption2)
                    Text(dep.displaySource)
                        .font(HIGTypography.caption2.weight(.medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                .padding(.vertical, HIGTokens.Spacing.xxs)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
            }
            
            // Annotation message
            if let msg = dep.annotations?.message, !msg.isEmpty {
                Text(msg)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            
            // Footer: Timestamp + Author + ID
            HStack(spacing: HIGTokens.Spacing.sm) {
                if let created = dep.createdOn, let date = DateFormatters.parseISO8601(created) {
                    HStack(spacing: HIGTokens.Spacing.xxs) {
                        Image(systemName: "clock")
                            .font(HIGTypography.caption2)
                        Text(date.relativeFormatted())
                            .font(HIGTypography.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                if let author = dep.authorEmail ?? dep.author, !author.isEmpty {
                    Text("•")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.tertiary)
                    
                    HStack(spacing: HIGTokens.Spacing.xxs) {
                        Image(systemName: "person.circle")
                            .font(HIGTypography.caption2)
                        Text(author)
                            .font(HIGTypography.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(dep.id.prefix(7))
                    .font(HIGTypography.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    private func sourceIcon(for source: String?) -> String {
        guard let s = source?.lowercased() else { return "cloud" }
        if s.contains("wrangler") { return "terminal.fill" }
        if s.contains("dash") { return "macwindow" }
        if s.contains("git") { return "arrow.triangle.branch" }
        if s.contains("rollback") { return "arrow.counterclockwise" }
        if s.contains("api") { return "network" }
        return "cloud"
    }
}
