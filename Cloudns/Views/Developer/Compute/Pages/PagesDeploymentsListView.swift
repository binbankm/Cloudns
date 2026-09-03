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
            .padding(.horizontal, HIGTokens.Spacing.md)
            .padding(.vertical, HIGTokens.Spacing.sm)
            .background(Color.higGroupBackground)
            .onChange(of: selectedEnvFilter) { _ in
                HIGFeedback.selection()
            }
            
            List {
                if !filteredDeployments.isEmpty {
                    Section(
                        header: Text("Deployments (\(filteredDeployments.count))"),
                        footer: Text("Tap any deployment to inspect the full build pipeline, stage durations, and console logs.")
                    ) {
                        ForEach(filteredDeployments) { dep in
                            Button {
                                HIGFeedback.impact(.light)
                                selectedDeployment = dep
                            } label: {
                                deploymentRow(dep)
                            }
                            .buttonStyle(.higPressable)
                            .contextMenu {
                                if let urlStr = dep.url, let url = URL(string: urlStr) {
                                    Link(destination: url) {
                                        Label("Open Preview in Safari", systemImage: "safari")
                                    }
                                    
                                    Button {
                                        UIPasteboard.general.string = urlStr
                                        ToastManager.shared.showCopied("Preview URL Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Preview URL", systemImage: "doc.on.doc")
                                    }
                                }
                                
                                if let hash = dep.deploymentTrigger?.metadata?.commitHash {
                                    Button {
                                        UIPasteboard.general.string = hash
                                        ToastManager.shared.showCopied("Commit Hash Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Commit Hash", systemImage: "number")
                                    }
                                }
                                
                                Button {
                                    UIPasteboard.general.string = dep.id
                                    ToastManager.shared.showCopied("Deployment ID Copied")
                                    HIGFeedback.copied()
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
                                    UIPasteboard.general.string = dep.id
                                    ToastManager.shared.showCopied("Deployment ID Copied")
                                    HIGFeedback.copied()
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
        }
        .background(Color(.systemGroupedBackground))
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
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Deployments…"))
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.deployments.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchProjectDetails() } }
                        )
                    )
                } else if viewModel.deployments.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Deployments",
                            systemImage: "clock.arrow.circlepath",
                            description: "No deployment history found for Pages project '\(projectName)'."
                        )
                    )
                } else if filteredDeployments.isEmpty && !searchText.isEmpty {
                    HIGContentState(.search(query: searchText))
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
            .higToast()
        }
    }
    
    // MARK: - Deployment Row View
    
    @ViewBuilder
    private func deploymentRow(_ dep: PagesDeployment) -> some View {
        let isProd = (dep.environment ?? "").lowercased() == "production"
        let status = (dep.latestStage?.status ?? "success").lowercased()
        let isSuccess = status == "success"
        let isFailure = status == "failure" || status == "error"
        
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
            // Header: Status + Environment Badge + Branch + Commit Hash
            HStack(alignment: .center, spacing: HIGTokens.Spacing.sm) {
                // Status Indicator Badge
                HStack(spacing: HIGTokens.Spacing.xs) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : (isFailure ? "xmark.circle.fill" : "arrow.triangle.2.circlepath"))
                        .font(HIGTypography.caption2)
                        .foregroundStyle(isSuccess ? HIGColors.success : (isFailure ? HIGColors.error : .orange))
                    
                    Text(isSuccess ? "Success" : (isFailure ? "Failed" : status.capitalized))
                        .font(HIGTypography.caption2.weight(.bold))
                }
                .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                .padding(.vertical, HIGTokens.Spacing.xxs + 0.5)
                .background(isSuccess ? HIGColors.success.opacity(0.12) : (isFailure ? HIGColors.error.opacity(0.12) : Color.orange.opacity(0.12)))
                .foregroundStyle(isSuccess ? HIGColors.success : (isFailure ? HIGColors.error : .orange))
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.sm, style: .continuous))
                
                // Environment Badge
                HIGBadge(
                    .custom(
                        color: isProd ? .blue : .purple,
                        text: isProd ? "Production" : "Preview"
                    ),
                    isCompact: true
                )
                
                Spacer()
                
                // Git Branch
                if let branch = dep.deploymentTrigger?.metadata?.branch, !branch.isEmpty {
                    HStack(spacing: HIGTokens.Spacing.xxs + 1) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(HIGTypography.caption2)
                        Text(branch)
                            .font(HIGTypography.caption2.monospaced())
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                    .padding(.vertical, HIGTokens.Spacing.xxs + 0.5)
                    .background(Color(.secondarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                }
                
                // Commit Hash
                if let hash = dep.deploymentTrigger?.metadata?.commitHash, !hash.isEmpty {
                    Text(String(hash.prefix(7)))
                        .font(HIGTypography.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                        .padding(.vertical, HIGTokens.Spacing.xxs + 0.5)
                        .background(Color(.secondarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                }
                
                Image(systemName: "chevron.right")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            
            // Commit Message
            if let msg = dep.deploymentTrigger?.metadata?.commitMessage, !msg.isEmpty {
                Text(msg)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            } else {
                Text("Direct Deployment via Cloudflare Pages")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Footer: Timestamp + Preview URL indicator
            HStack(spacing: HIGTokens.Spacing.sm) {
                if let created = dep.createdOn, let date = DateFormatters.parseISO8601(created) {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(HIGTypography.caption2)
                        Text(date.relativeFormatted())
                            .font(HIGTypography.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let urlStr = dep.url, !urlStr.isEmpty {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Image(systemName: "globe")
                            .font(HIGTypography.caption2)
                        Text(verbatim: urlStr.replacingOccurrences(of: "https://", with: ""))
                            .font(HIGTypography.caption2.monospaced())
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.higAccent)
                }
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xs)
        .contentShape(Rectangle())
    }
}
