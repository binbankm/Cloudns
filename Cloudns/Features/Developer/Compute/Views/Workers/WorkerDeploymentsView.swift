import SwiftUI

// MARK: - WorkerDeploymentsView

struct WorkerDeploymentsView: View {
    // MARK: - Properties
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
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search Deployments"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(CloudnsColor.groupedBackground)
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(WorkerDeployment.placeholders) { placeholder in
                            deploymentRow(placeholder, isLatest: placeholder.number == 4)
                        }
                    }
                    .skeletonLoading(true)
                } else if !viewModel.filteredDeployments.isEmpty {
                    Section(header: Text("Deployments (\(viewModel.deployments.count))"), footer: Text("Roll back to any previous deployment to instantly restore Worker code and configuration.")) {
                        ForEach(Array(viewModel.filteredDeployments.enumerated()), id: \.element.id) { index, dep in
                            deploymentRow(dep, isLatest: index == 0)
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
                                        UIPasteboard.general.string = dep.id
                                        HapticManager.notification(.success)
                                        CloudnsToastManager.shared.showCopied("Deployment ID copied")
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
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
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
                        CloudnsToastManager.shared.showSuccess("Rollback Succeeded", message: "Worker restored to Version #\(dep.number ?? 1)")
                    } else {
                        CloudnsToastManager.shared.showError("Rollback Failed", message: viewModel.errorMessage ?? "Unknown error")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { dep in
            Text("Are you sure you want to rollback '\(scriptName)' to Version #\(dep.number ?? 1)? Traffic will immediately be served by this version.")
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.deployments.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchDeployments() } }
                        )
                    )
                } else if viewModel.deployments.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "clock.arrow.circlepath",
                            title: "No Deployments",
                            message: "No deployment history found for Worker '\(scriptName)'.",
                            actionTitle: "Refresh",
                            action: { Task { await viewModel.fetchDeployments() } }
                        )
                    )
                } else if viewModel.filteredDeployments.isEmpty && !viewModel.searchText.isEmpty {
                    CloudnsStateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
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
    // MARK: - Private Views
    private func deploymentRow(_ dep: WorkerDeployment, isLatest: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                // Version Tag
                if let num = dep.number {
                    Text("v\(num)")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundStyle(isLatest ? .white : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isLatest ? Color.green : Color(.secondarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                if isLatest {
                    CloudnsBadge(.active("Active / Current"), isCompact: true)
                }
                
                Spacer()
                
                // Source Badge
                Text(dep.displaySource)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.secondarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Message or Description
            if let msg = dep.annotations?.message, !msg.isEmpty {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            
            // Metadata Footer
            HStack(spacing: 8) {
                if let created = dep.createdOn {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(DateFormatters.formatISO8601ToDisplay(created, style: DateFormatters.mediumDateTime))
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let author = dep.authorEmail ?? dep.author, !author.isEmpty {
                    Text(author)
                        .font(.caption2)
                        .foregroundStyle(Color(.tertiaryLabel))
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
