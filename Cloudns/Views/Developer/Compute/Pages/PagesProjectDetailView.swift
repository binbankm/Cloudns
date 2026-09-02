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
                            HIGFeedback.impact(.medium)
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Project", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More Actions")
                    .higTouchTarget(44)
                }
            }
            .confirmationDialog("Delete Pages Project", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                Button("Delete '\(project.name)'", role: .destructive) {
                    Task {
                        do {
                            try await PagesService.shared.deletePagesProject(accountId: accountId, projectName: project.name)
                            ToastManager.shared.showSuccess("Pages Project Deleted", icon: "trash.fill")
                            HIGFeedback.success()
                            dismiss()
                        } catch {
                            ToastManager.shared.showError("Failed to Delete Pages Project")
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
                                    .higTouchTarget(44)
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
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.md) {
                    HStack(alignment: .top, spacing: HIGTokens.Spacing.md) {
                        Image(systemName: "macwindow")
                            .font(HIGTypography.title2)
                            .foregroundStyle(.white)
                            .frame(width: HIGTokens.Size.minTouchTarget, height: HIGTokens.Size.minTouchTarget)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                            .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text(project.name)
                                .font(HIGTypography.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            HStack(spacing: HIGTokens.Spacing.xs + 2) {
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
                        
                        HStack(spacing: HIGTokens.Spacing.sm + 2) {
                            Image(systemName: "globe")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                Text("Production URL")
                                    .font(HIGTypography.caption2)
                                    .foregroundStyle(.secondary)
                                Text("https://\(sub)")
                                    .font(HIGTypography.caption.monospaced())
                                    .foregroundStyle(Color.higAccent)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = "https://\(sub)"
                                ToastManager.shared.showCopied("Production URL Copied")
                                HIGFeedback.copied()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(HIGTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Copy Production URL")
                            
                            Link(destination: url) {
                                Image(systemName: "arrow.up.right")
                                    .font(HIGTypography.caption)
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
                .padding(.vertical, HIGTokens.Spacing.xxs)
            }
            
            // MARK: - Project Details
            Section(header: Text("Project Details")) {
                if let branch = project.productionBranch {
                    HStack {
                        Label {
                            Text("Production Branch")
                                .font(HIGTypography.body)
                        } icon: {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundStyle(.blue)
                        }
                        .foregroundStyle(.primary)
                        Spacer()
                        Text(branch)
                            .font(HIGTypography.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let repo = project.source?.config?.repoName {
                    HStack {
                        Label {
                            Text("Repository")
                                .font(HIGTypography.body)
                        } icon: {
                            Image(systemName: "folder")
                                .foregroundStyle(.purple)
                        }
                        .foregroundStyle(.primary)
                        Spacer()
                        Text(repo)
                            .font(HIGTypography.body)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let created = project.createdOn {
                    HStack {
                        Label {
                            Text("Created Date")
                                .font(HIGTypography.body)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                        }
                        .foregroundStyle(.primary)
                        Spacer()
                        Text(created.prefix(10))
                            .font(HIGTypography.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // MARK: - Features Navigation
            Section(header: Text("Management")) {
                NavigationLink {
                    PagesAnalyticsView(accountId: accountId, projectName: project.name)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "chart.xyaxis.line", color: .purple)
                        Text("Analytics & Metrics")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                NavigationLink {
                    PagesDeploymentsListView(accountId: accountId, projectName: project.name, viewModel: viewModel)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "clock.arrow.circlepath", color: .orange)
                        Text("Deployments History")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.deployments.isEmpty {
                            Text("\(viewModel.deployments.count)")
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    PagesDomainsView(accountId: accountId, projectName: project.name, viewModel: viewModel)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "globe", color: .blue)
                        Text("Custom Domains")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.domains.isEmpty {
                            Text("\(viewModel.domains.count)")
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    PagesVariablesView(accountId: accountId, project: project)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "key.fill", color: HIGColors.success)
                        Text("Variables & Secrets")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                NavigationLink {
                    PagesBindingsView(accountId: accountId, project: project)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "link.badge.plus", color: .indigo)
                        Text("Resource Bindings")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                Button {
                    showingBuildConfigSheet = true
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "gearshape.fill", color: .orange)
                        Text("Build Configuration")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(HIGTypography.caption2.weight(.semibold))
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
