import SwiftUI

// MARK: - PagesDeploymentsListView
// Apple HIG Compliant Cloudflare Pages Deployment Timeline & Pipeline History

struct PagesDeploymentsListView: View {
    let accountId: String
    let projectName: String
    @ObservedObject var viewModel: PagesProjectDetailViewModel
    
    @State private var selectedEnvFilter = "all" // "all" | "production" | "preview"
    @State private var searchText = ""
    @State private var selectedDeployment: PagesDeployment?
    
    private var productionDeployments: [PagesDeployment] {
        viewModel.deployments.filter { ($0.environment ?? "").lowercased() == "production" }
    }
    
    private var previewDeployments: [PagesDeployment] {
        viewModel.deployments.filter { ($0.environment ?? "").lowercased() != "production" }
    }
    
    private var filteredDeployments: [PagesDeployment] {
        var list = viewModel.deployments
        if selectedEnvFilter == "production" {
            list = productionDeployments
        } else if selectedEnvFilter == "preview" {
            list = previewDeployments
        }
        
        if searchText.isEmpty {
            return list
        }
        return list.filter { dep in
            (dep.environment ?? "").localizedStandardContains(searchText) ||
            (dep.latestStage?.status ?? "").localizedStandardContains(searchText) ||
            (dep.deploymentTrigger?.metadata?.commitMessage ?? "").localizedStandardContains(searchText) ||
            (dep.deploymentTrigger?.metadata?.branch ?? "").localizedStandardContains(searchText) ||
            (dep.deploymentTrigger?.metadata?.commitHash ?? "").localizedStandardContains(searchText) ||
            (dep.id).localizedStandardContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Environment Filter Bar
            Picker("Environment", selection: $selectedEnvFilter) {
                Text("All (\(viewModel.deployments.count))").tag("all")
                Text("Production (\(productionDeployments.count))").tag("production")
                Text("Preview (\(previewDeployments.count))").tag("preview")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemGroupedBackground))
            .onChange(of: selectedEnvFilter) { _ in
                HapticManager.selection()
            }
            
            List {
                if !filteredDeployments.isEmpty {
                    Section(
                        header: Text("Deployments (\(filteredDeployments.count))"),
                        footer: Text("Tap any deployment to inspect the full build pipeline, stage durations, and console logs.")
                    ) {
                        ForEach(filteredDeployments) { dep in
                            Button {
                                HapticManager.impact(.light)
                                selectedDeployment = dep
                            } label: {
                                deploymentRow(dep)
                            }
                            .foregroundStyle(.primary)
                            .contextMenu {
                                if let urlStr = dep.url, let url = URL(string: urlStr) {
                                    Link(destination: url) {
                                        Label("Open Preview in Safari", systemImage: "safari")
                                    }
                                    
                                    Button {
                                        copyToClipboard(urlStr, toast: "Preview URL Copied")
                                    } label: {
                                        Label("Copy Preview URL", systemImage: "doc.on.doc")
                                    }
                                }
                                
                                if let hash = dep.deploymentTrigger?.metadata?.commitHash {
                                    Button {
                                        copyToClipboard(hash, toast: "Commit Hash Copied")
                                    } label: {
                                        Label("Copy Commit Hash", systemImage: "number")
                                    }
                                }
                                
                                Button {
                                    copyToClipboard(dep.id, toast: "Deployment ID Copied")
                                } label: {
                                    Label("Copy Deployment ID", systemImage: "doc.on.doc")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if let urlStr = dep.url, let url = URL(string: urlStr) {
                                    Link(destination: url) {
                                        Label("Preview", systemImage: "safari")
                                    }
                                    .tint(.blue)
                                }
                                
                                Button {
                                    copyToClipboard(dep.id, toast: "Deployment ID Copied")
                                } label: {
                                    Label("Copy ID", systemImage: "doc.on.doc")
                                }
                                .tint(.gray)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listState(
                isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
                loadingMessage: "Loading Deployments…",
                isEmpty: viewModel.hasFetchedData && viewModel.deployments.isEmpty,
                emptyTitle: "No Deployments",
                emptySystemImage: "clock.arrow.circlepath",
                emptyDescription: "No deployment history found for Pages project '\(projectName)'.",
                isSearchEmpty: viewModel.hasFetchedData && filteredDeployments.isEmpty && !searchText.isEmpty,
                searchQuery: searchText,
                errorMessage: (viewModel.hasFetchedData && viewModel.deployments.isEmpty) ? viewModel.errorMessage.map { LocalizedStringKey($0) } : nil,
                retryAction: { Task { await viewModel.fetchProjectDetails() } }
            )
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search by Commit, Branch, or ID"
        )
        .navigationTitle("Deployments History")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchProjectDetails()
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
    
    // MARK: - Deployment Row View
    
    @ViewBuilder
    private func deploymentRow(_ dep: PagesDeployment) -> some View {
        let isProd = (dep.environment ?? "").lowercased() == "production"
        let status = (dep.latestStage?.status ?? "success").lowercased()
        let isSuccess = status == "success"
        let isFailure = status == "failure" || status == "error"
        
        VStack(alignment: .leading, spacing: 8) {
            // Header: Status + Environment Badge + Branch + Commit Hash
            HStack(alignment: .center, spacing: 8) {
                // Status Indicator Badge
                HStack(spacing: 4) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : (isFailure ? "xmark.circle.fill" : "arrow.triangle.2.circlepath"))
                        .font(.caption2)
                        .foregroundStyle(isSuccess ? .green : (isFailure ? .red : .orange))
                    
                    Text(isSuccess ? "Success" : (isFailure ? "Failed" : status.capitalized))
                        .font(.caption2.weight(.bold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(isSuccess ? Color.green.opacity(0.12) : (isFailure ? Color.red.opacity(0.12) : Color.orange.opacity(0.12)))
                .foregroundStyle(isSuccess ? .green : (isFailure ? .red : .orange))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                // Environment Badge
                Text(isProd ? "Production" : "Preview")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isProd ? .blue : .purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((isProd ? Color.blue : Color.purple).opacity(0.12)))
                
                Spacer()
                
                // Git Branch
                if let branch = dep.deploymentTrigger?.metadata?.branch, !branch.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                        Text(branch)
                            .font(.caption2.monospaced())
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color(.secondarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                
                // Commit Hash
                if let hash = dep.deploymentTrigger?.metadata?.commitHash, !hash.isEmpty {
                    Text(String(hash.prefix(7)))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color(.secondarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            
            // Commit Message
            if let msg = dep.deploymentTrigger?.metadata?.commitMessage, !msg.isEmpty {
                Text(msg)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            } else {
                Text("Direct Deployment via Cloudflare Pages")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Footer: Timestamp + Preview URL indicator
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
                
                Spacer()
                
                if let urlStr = dep.url, !urlStr.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.caption2)
                        Text(verbatim: urlStr.replacingOccurrences(of: "https://", with: ""))
                            .font(.caption2.monospaced())
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
