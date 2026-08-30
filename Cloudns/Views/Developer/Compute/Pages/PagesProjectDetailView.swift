import SwiftUI

struct PagesProjectDetailView: View {
    let accountId: String
    let project: PagesProject
    @StateObject private var viewModel: PagesProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingDomainsSheet = false
    @State private var showingBuildConfigSheet = false
    
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
                ToolbarItem(placement: .topBarTrailing) {
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
                            HIGFeedback.impact(.medium)
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
                            HIGFeedback.success()
                            dismiss()
                        } catch {
                            HIGFeedback.error()
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
            .onAppear {
                WidgetDataStore.shared.syncPagesWithAnalytics(project: project, accountId: accountId)
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
                 .higToast()
            }
            .sheet(isPresented: $showingBuildConfigSheet) {
                PagesBuildConfigEditorView(accountId: accountId, project: project, parentViewModel: viewModel)
                 .higToast()
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            // MARK: - Hero & Project Overview Card
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "macwindow")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            HStack(spacing: 6) {
                                if let branch = project.productionBranch {
                                    HIGBadge(.active(branch), isCompact: true)
                                }
                                if let cmd = project.buildConfig?.buildCommand, !cmd.isEmpty {
                                    HIGBadge(.custom(color: .purple, text: cmd), isCompact: true)
                                }
                            }
                        }
                    }
                    
                    if let sub = project.subdomain, let url = URL(string: "https://\(sub)") {
                        Divider()
                        
                        HStack(spacing: 10) {
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Production URL")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("https://\(sub)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.blue)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = "https://\(sub)"
                                ToastManager.shared.showCopied()
                                HIGFeedback.success()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Copy Production URL")
                            
                            Link(destination: url) {
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open Production URL")
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - Project Details
            Section(header: Text("Project Details")) {
                if let branch = project.productionBranch {
                    HStack {
                        Label {
                            Text("Production Branch")
                        } icon: {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundStyle(.blue)
                        }
                        .foregroundStyle(.primary)
                        Spacer()
                        Text(branch)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let repo = project.source?.config?.repoName {
                    HStack {
                        Label {
                            Text("Repository")
                        } icon: {
                            Image(systemName: "folder")
                                .foregroundStyle(.purple)
                        }
                        .foregroundStyle(.primary)
                        Spacer()
                        Text(repo)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let created = project.createdOn {
                    HStack {
                        Label {
                            Text("Created Date")
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                        }
                        .foregroundStyle(.primary)
                        Spacer()
                        Text(created.prefix(10))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // MARK: - Features Navigation
            Section(header: Text("Management")) {
                NavigationLink {
                    PagesAnalyticsView(accountId: accountId, projectName: project.name)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "chart.xyaxis.line", color: .purple)
                        Text("Analytics & Metrics")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                NavigationLink {
                    PagesDeploymentsListView(accountId: accountId, projectName: project.name, viewModel: viewModel)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "clock.arrow.circlepath", color: .orange)
                        Text("Deployments History")
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.deployments.isEmpty {
                            Text("\(viewModel.deployments.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    PagesDomainsView(accountId: accountId, projectName: project.name, viewModel: viewModel)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "globe", color: .blue)
                        Text("Custom Domains")
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.domains.isEmpty {
                            Text("\(viewModel.domains.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    PagesVariablesView(accountId: accountId, project: project)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "key.fill", color: .green)
                        Text("Variables & Secrets")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                NavigationLink {
                    PagesBindingsView(accountId: accountId, project: project)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "link.badge.plus", color: .indigo)
                        Text("Resource Bindings")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                Button {
                    showingBuildConfigSheet = true
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "gearshape.fill", color: .orange)
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
            }
        }
        .listStyle(.insetGrouped)
    }
}
