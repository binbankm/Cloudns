import SwiftUI

// MARK: - PagesProjectDetailView
// Apple HIG Compliant Cloudflare Pages Project Hub & Top-level Management

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
                            ToastManager.shared.showSuccess("Pages Project Deleted", icon: "trash.fill")
                            HapticManager.notification(.success)
                            dismiss()
                        } catch {
                            ToastManager.shared.showError("Failed to Delete Pages Project")
                            HapticManager.notification(.error)
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
            }
            .sheet(isPresented: $showingBuildConfigSheet) {
                PagesBuildConfigEditorView(accountId: accountId, project: project, parentViewModel: viewModel)
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            // MARK: - Hero & Project Overview Card
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
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
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            HStack(spacing: 6) {
                                if let branch = project.productionBranch {
                                    Text(branch)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.green.opacity(0.12)))
                                }
                                if let cmd = project.buildConfig?.buildCommand, !cmd.isEmpty {
                                    Text(cmd)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.purple)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.purple.opacity(0.12)))
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
                                    .foregroundStyle(Color.accentColor)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button {
                                copyToClipboard("https://\(sub)", toast: "Production URL Copied")
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Circle())
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .hoverEffect(.highlight)
                            .accessibilityLabel("Copy Production URL")
                            
                            Link(destination: url) {
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Circle())
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .hoverEffect(.highlight)
                            .accessibilityLabel("Open Production URL")
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            
            // MARK: - Project Details
            Section(header: Text("Project Details")) {
                if let branch = project.productionBranch {
                    HStack {
                        Label {
                            Text("Production Branch")
                                .font(.body)
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
                                .font(.body)
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
                                .font(.body)
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
                            .font(.body)
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
                            .font(.body)
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
                            .font(.body)
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
                            .font(.body)
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
                            .font(.body)
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
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
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
