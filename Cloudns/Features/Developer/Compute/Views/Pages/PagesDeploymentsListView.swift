import SwiftUI

// MARK: - PagesDeploymentsListView

struct PagesDeploymentsListView: View {
    // MARK: - Properties
    let accountId: String
    let projectName: String
    @ObservedObject var viewModel: PagesProjectDetailViewModel
    
    @State private var searchText = ""
    @State private var selectedDeployment: PagesDeployment?
    
    private var filteredDeployments: [PagesDeployment] {
        if searchText.isEmpty {
            return viewModel.deployments
        }
        return viewModel.deployments.filter { dep in
            (dep.environment ?? "").localizedStandardContains(searchText) ||
            (dep.latestStage?.status ?? "").localizedStandardContains(searchText) ||
            (dep.deploymentTrigger?.metadata?.commitMessage ?? "").localizedStandardContains(searchText) ||
            (dep.deploymentTrigger?.metadata?.commitHash ?? "").localizedStandardContains(searchText) ||
            (dep.id).localizedStandardContains(searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $searchText,
                prompt: "Search Deployments"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(PagesDeployment.placeholders) { dep in
                            deploymentRow(dep)
                        }
                    }
                    .skeletonLoading(true)
                } else if !filteredDeployments.isEmpty {
                    Section(
                        header: Text("Deployments (\(filteredDeployments.count))"),
                        footer: Text("Tap any deployment to view build logs, stage status, and environment variables.")
                    ) {
                        ForEach(filteredDeployments) { dep in
                            Button {
                                HapticManager.impact(.light)
                                selectedDeployment = dep
                            } label: {
                                deploymentRow(dep)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Deployments History")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchProjectDetails()
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.deployments.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchProjectDetails() } }
                        )
                    )
                } else if viewModel.deployments.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "clock.arrow.circlepath",
                            title: "No Deployments",
                            message: "No deployment history found for Pages project '\(projectName)'."
                        )
                    )
                } else if filteredDeployments.isEmpty && !searchText.isEmpty {
                    CloudnsStateOverlayView(
                        state: .search(
                            query: searchText,
                            clearAction: { searchText = "" }
                        )
                    )
                }
            }
        }
        .sheet(item: $selectedDeployment) { dep in
            NavigationStack {
                PagesDeploymentDetailView(
                    accountId: accountId,
                    projectName: projectName,
                    deployment: dep,
                    parentViewModel: viewModel
                )
            }
        }
    }
    
    @ViewBuilder
    // MARK: - Private Views
    private func deploymentRow(_ dep: PagesDeployment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                CloudnsBadge(
                    (dep.latestStage?.status == "success") ? .active((dep.environment ?? "Production").capitalized) : .warning((dep.environment ?? "Preview").capitalized),
                    isCompact: true
                )
                
                Spacer()
                
                if let trigger = dep.deploymentTrigger?.metadata?.commitHash {
                    Text(String(trigger.prefix(7)))
                        .font(.caption2.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(.primary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            
            if let msg = dep.deploymentTrigger?.metadata?.commitMessage, !msg.isEmpty {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            if let created = dep.createdOn {
                Text(created.prefix(19).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
