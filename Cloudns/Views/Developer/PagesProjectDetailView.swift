import SwiftUI

struct PagesProjectDetailView: View {
    let accountId: String
    let project: PagesProject
    @StateObject private var viewModel: PagesProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingDomainsSheet = false
    @State private var showingBuildConfigSheet = false
    @State private var selectedDeployment: PagesDeployment?
    
    init(accountId: String, project: PagesProject) {
        self.accountId = accountId
        self.project = project
        _viewModel = StateObject(wrappedValue: PagesProjectDetailViewModel(accountId: accountId, project: project))
    }
    
    var body: some View {
        contentView
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if let sub = project.subdomain, let url = URL(string: "https://\(sub)") {
                            Link(destination: url) {
                                Label("Open Project URL", systemImage: "safari")
                            }
                        }
                        
                        Button {
                            showingBuildConfigSheet = true
                        } label: {
                            Label("Build Configuration", systemImage: "gearshape")
                        }
                        
                        Button {
                            showingDomainsSheet = true
                        } label: {
                            Label("Custom Domains", systemImage: "globe")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            HapticManager.impact(.medium)
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Project", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More Actions")
                }
            }
            .confirmationDialog("Delete Pages Project", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                Button("Delete '\(project.name)'", role: .destructive) {
                    Task {
                        do {
                            try await PagesService.shared.deletePagesProject(accountId: accountId, projectName: project.name)
                            ToastManager.shared.showSuccess("Pages Project Deleted", message: project.name)
                            dismiss()
                        } catch {
                            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete Pages project '\(project.name)'? Deployments and hosted assets will be permanently removed.")
            }
            .refreshable {
                await viewModel.fetchProjectDetails()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchProjectDetails()
                }
            }
            .sheet(isPresented: $showingDomainsSheet) {
                NavigationStack {
                    PagesDomainsView(accountId: accountId, projectName: project.name, viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingDomainsSheet = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingBuildConfigSheet) {
                PagesBuildConfigEditorView(accountId: accountId, project: project, parentViewModel: viewModel)
            }
            .sheet(item: $selectedDeployment) { dep in
                NavigationStack {
                    PagesDeploymentDetailView(
                        accountId: accountId,
                        projectName: project.name,
                        deployment: dep,
                        parentViewModel: viewModel
                    )
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            // MARK: - Project Info
            Section(header: Text("Project Overview")) {
                HStack {
                    Text("Project Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(project.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                
                if let sub = project.subdomain, let url = URL(string: "https://\(sub)") {
                    Link(destination: url) {
                        HStack {
                            Text("Production URL")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(sub)
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                if let branch = project.productionBranch {
                    HStack {
                        Text("Production Branch")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(branch)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let repo = project.source?.config?.repoName {
                    HStack {
                        Text("Repository")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(repo)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // MARK: - Features Navigation
            Section(header: Text("Management")) {
                Button {
                    showingDomainsSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Custom Domains")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(viewModel.domains.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    PagesBindingsView(project: project)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body)
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Bindings & Variables")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                Button {
                    showingBuildConfigSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Build Configuration")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    PagesAnalyticsView(accountId: accountId, projectName: project.name)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.body)
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Analytics & Metrics")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
            }
            
            // MARK: - Deployments History
            Section(header: Text("Deployments History (\(viewModel.deployments.count))")) {
                if !viewModel.hasFetchedData {
                    ForEach(PagesDeployment.placeholders) { dep in
                        deploymentRow(dep)
                    }
                    .skeletonLoading(true)
                } else if viewModel.deployments.isEmpty {
                    Text("No recent deployments found.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.deployments) { dep in
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
        .centerConstrainedWidth(maxWidth: 840)
    }
    
    @ViewBuilder
    private func deploymentRow(_ dep: PagesDeployment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    CloudnsBadge((dep.latestStage?.status == "success") ? .active((dep.environment ?? "Production").capitalized) : .warning((dep.environment ?? "Preview").capitalized), isCompact: true)
                }
                
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
    }
}
