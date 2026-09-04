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
                                        HapticManager.impact(.medium)
                                        deploymentToRollback = dep
                                        showingRollbackAlert = true
                                    } label: {
                                        Label("Rollback to Version #\(dep.number ?? 1)", systemImage: "arrow.counterclockwise")
                                    }
                                }
                                
                                Button {
                                    copyToClipboard(dep.id, toast: "Deployment ID Copied")
                                } label: {
                                    Label("Copy Deployment ID", systemImage: "doc.on.doc")
                                }
                                
                                if let author = dep.authorEmail ?? dep.author, !author.isEmpty {
                                    Button {
                                        copyToClipboard(author, toast: "Author Email Copied")
                                    } label: {
                                        Label("Copy Author Email", systemImage: "envelope")
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if index != 0 {
                                    Button {
                                        HapticManager.impact(.medium)
                                        deploymentToRollback = dep
                                        showingRollbackAlert = true
                                    } label: {
                                        Label("Rollback", systemImage: "arrow.counterclockwise")
                                    }
                                    .tint(.orange)
                                }
                                
                                Button {
                                    copyToClipboard(dep.id, toast: "Deployment ID Copied")
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
                HapticManager.impact(.heavy)
                Task {
                    let success = await viewModel.rollback(deployment: dep)
                    if success {
                        ToastManager.shared.showSuccess("Rolled back to Version #\(dep.number ?? 1)", icon: "arrow.counterclockwise")
                        HapticManager.notification(.success)
                    } else {
                        ToastManager.shared.showError("Failed to Roll Back")
                        HapticManager.notification(.error)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { dep in
            Text("Are you sure you want to rollback '\(scriptName)' to Version #\(dep.number ?? 1)? Traffic will immediately be routed to this deployment version.")
        }
        .listState(
            isLoading: viewModel.isLoading && !viewModel.hasFetchedData,
            loadingMessage: "Loading Deployments…",
            isEmpty: viewModel.hasFetchedData && viewModel.deployments.isEmpty,
            emptyTitle: "No Deployments",
            emptySystemImage: "clock.arrow.circlepath",
            emptyDescription: "No deployment history found for Worker '\(scriptName)'.",
            emptyActionTitle: "Refresh",
            emptyAction: { Task { await viewModel.fetchDeployments() } },
            isSearchEmpty: viewModel.hasFetchedData && viewModel.filteredDeployments.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: (viewModel.hasFetchedData && viewModel.deployments.isEmpty) ? viewModel.errorMessage.map { LocalizedStringKey($0) } : nil,
            retryAction: { Task { await viewModel.fetchDeployments() } }
        )
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchDeployments()
            }
        }
    }
    
    // MARK: - Row Subview
    @ViewBuilder
    private func deploymentRow(_ dep: WorkerDeployment, isLatest: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Version + Status + Source
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: isLatest ? "checkmark.circle.fill" : "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(isLatest ? .green : .secondary)
                    
                    Text("v\(dep.number ?? 1)")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(isLatest ? Color.green.opacity(0.12) : Color(.secondarySystemFill))
                .foregroundStyle(isLatest ? Color.green : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                if isLatest {
                    Text("Active")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: sourceIcon(for: dep.source))
                        .font(.caption2)
                    Text(dep.displaySource)
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            
            // Annotation message
            if let msg = dep.annotations?.message, !msg.isEmpty {
                Text(msg)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            
            // Footer: Timestamp + Author + ID
            HStack(spacing: 8) {
                if let created = dep.createdOn, let date = DateFormatters.parseISO8601(created) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(date.relativeFormatted())
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                if let author = dep.authorEmail ?? dep.author, !author.isEmpty {
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption2)
                        Text(author)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(dep.id.prefix(7))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
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
