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
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Project", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Pages Project", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await CloudflareAPIClient.shared.deletePagesProject(accountId: accountId, projectName: project.name)
                            ToastManager.shared.showSuccess("Pages Project Deleted", message: project.name)
                            dismiss()
                        } catch {
                            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                        }
                    }
                }
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
            .toastContainer()
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else {
                // Section: Project Info
                Section(header: Text("Project Overview")) {
                    HStack {
                        Text("Project Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(project.name)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    if let sub = project.subdomain, let url = URL(string: "https://\(sub)") {
                        Link(destination: url) {
                            HStack {
                                Text("Production URL")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(sub)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    if let branch = project.productionBranch {
                        HStack {
                            Text("Production Branch")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(branch)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let repo = project.source?.config?.repoName {
                        HStack {
                            Text("Repository")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(repo)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Section: Features Navigation
                Section(header: Text("Management")) {
                    Button {
                        showingDomainsSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Custom Domains")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(viewModel.domains.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    
                    Button {
                        showingBuildConfigSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape")
                                .font(.body)
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Build Configuration")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                }
                
                // Section: Deployments History
                Section(header: Text("Deployments History (\(viewModel.deployments.count))")) {
                    if viewModel.deployments.isEmpty {
                        Text("No recent deployments found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.deployments) { dep in
                            Button {
                                selectedDeployment = dep
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill((dep.latestStage?.status == "success") ? Color.green : Color.orange)
                                                .frame(width: 8, height: 8)
                                            Text((dep.environment ?? "Production").capitalized)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        if let trigger = dep.deploymentTrigger?.metadata?.commitHash {
                                            Text(String(trigger.prefix(7)))
                                                .font(.caption2.monospacedDigit())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(UIColor.secondarySystemFill))
                                                .cornerRadius(4)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(Color(UIColor.tertiaryLabel))
                                    }
                                    
                                    if let msg = dep.deploymentTrigger?.metadata?.commitMessage, !msg.isEmpty {
                                        Text(msg)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    if let created = dep.createdOn {
                                        Text(created.prefix(19).replacingOccurrences(of: "T", with: " "))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
    }
}
