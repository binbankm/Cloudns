import SwiftUI

struct PagesDeploymentDetailView: View {
    // MARK: - Properties
    let accountId: String
    let projectName: String
    let deployment: PagesDeployment
    @ObservedObject var parentViewModel: PagesProjectDetailViewModel
    
    @StateObject private var viewModel: PagesDeploymentDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingRollbackAlert = false
    @State private var showingDeleteAlert = false
    @State private var isActionRunning = false
    
    // Log Viewer Controls
    @State private var isWrapLogs = true
    @State private var logSearchText = ""
    @State private var selectedLogFilter: LogFilter = .all
    @State private var isExpandedLog = false
    
    private enum LogFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case errors = "Errors"
        case warnings = "Warnings"
        var id: String { rawValue }
    }
    
    init(accountId: String, projectName: String, deployment: PagesDeployment, parentViewModel: PagesProjectDetailViewModel) {
        self.accountId = accountId
        self.projectName = projectName
        self.deployment = deployment
        self.parentViewModel = parentViewModel
        _viewModel = StateObject(wrappedValue: PagesDeploymentDetailViewModel(accountId: accountId, projectName: projectName, deployment: deployment))
    }
    
    var isSuccess: Bool { deployment.latestStage?.status == "success" }
    
    private var filteredLogs: [(index: Int, log: PagesDeploymentLog)] {
        let indexed = viewModel.logs.enumerated().map { (index: $0.offset + 1, log: $0.element) }
        return indexed.filter { item in
            let line = item.log.line
            let matchSearch = logSearchText.isEmpty || line.localizedCaseInsensitiveContains(logSearchText)
            switch selectedLogFilter {
            case .all:
                return matchSearch
            case .errors:
                let lower = line.lowercased()
                return matchSearch && (lower.contains("error") || lower.contains("failed") || lower.contains("fatal"))
            case .warnings:
                let lower = line.lowercased()
                return matchSearch && lower.contains("warn")
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        List {
            // MARK: - Overview
            Section(header: Text("Deployment Overview")) {
                HStack {
                    Text("Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    CloudnsBadge(isSuccess ? .active(deployment.latestStage?.status?.capitalized ?? "Success") : .warning(deployment.latestStage?.status?.capitalized ?? "Pending"), isCompact: true)
                }
                
                if let env = deployment.environment {
                    HStack {
                        Text("Environment")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(env.capitalized)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let branch = deployment.deploymentTrigger?.metadata?.branch {
                    HStack {
                        Text("Branch")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(branch)
                            .font(CloudnsTypography.body)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let hash = deployment.deploymentTrigger?.metadata?.commitHash {
                    HStack {
                        Text("Commit")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(hash.prefix(7)))
                            .font(CloudnsTypography.code)
                            .foregroundStyle(.primary)
                    }
                }
                
                if let msg = deployment.deploymentTrigger?.metadata?.commitMessage, !msg.isEmpty {
                    VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                        Text("Commit Message")
                            .font(CloudnsTypography.caption)
                            .foregroundStyle(.secondary)
                        Text(msg)
                            .font(CloudnsTypography.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, CloudnsSpacing.xxs)
                }
                
                if let urlStr = deployment.url, let url = URL(string: urlStr) {
                    Link(destination: url) {
                        HStack {
                            Text("Preview URL")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(urlStr)
                                .font(CloudnsTypography.caption)
                                .lineLimit(1)
                                .foregroundStyle(CloudnsColor.brand)
                            Image(systemName: "arrow.up.right")
                                .font(CloudnsTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // MARK: - Actions
            Section(header: Text("Actions")) {
                Button {
                    HapticManager.impact(.medium)
                    showingRollbackAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundStyle(CloudnsColor.brand)
                        Text("Rollback / Promote to Production")
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isActionRunning)
                
                Button {
                    HapticManager.impact(.medium)
                    Task {
                        isActionRunning = true
                        do {
                            try await parentViewModel.retryDeployment(id: deployment.id)
                            CloudnsToastManager.shared.showSuccess("Deployment Retried", message: "Build queued")
                            dismiss()
                        } catch {
                            CloudnsToastManager.shared.showError("Retry Failed", message: error.localizedDescription)
                        }
                        isActionRunning = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(CloudnsColor.warning)
                        Text("Retry Deployment")
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isActionRunning)
                
                Button(role: .destructive) {
                    HapticManager.impact(.medium)
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundStyle(CloudnsColor.danger)
                        Text("Delete Deployment")
                            .foregroundStyle(CloudnsColor.danger)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isActionRunning)
            }
            
            // MARK: - Build Logs Terminal Viewer
            Section(header: Text("Build Logs (\(viewModel.logs.count) lines)")) {
                if viewModel.isLoadingLogs {
                    VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                        ForEach(0..<4, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: CloudnsRadius.xs)
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 12)
                                .frame(maxWidth: idx == 3 ? 180 : .infinity)
                        }
                    }
                    .padding(CloudnsSpacing.mdMedium)
                    .background(terminalBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous))
                    .skeletonLoading(true)
                } else if viewModel.logs.isEmpty {
                    Text("No build logs available for this deployment.")
                        .font(CloudnsTypography.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, CloudnsSpacing.sm)
                } else {
                    buildLogsTerminalView
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Deployment Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .font(CloudnsTypography.headline)
            }
        }
        .task {
            await viewModel.fetchLogs()
        }
        .alert("Rollback to this Deployment?", isPresented: $showingRollbackAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Rollback", role: .destructive) {
                Task {
                    isActionRunning = true
                    do {
                        try await parentViewModel.rollbackDeployment(id: deployment.id)
                        CloudnsToastManager.shared.showSuccess("Rolled Back", message: "Promoted to production")
                        dismiss()
                    } catch {
                        CloudnsToastManager.shared.showError("Rollback Failed", message: error.localizedDescription)
                    }
                    isActionRunning = false
                }
            }
        } message: {
            Text("This will immediately switch your production Pages traffic to this historical deployment build.")
        }
        .alert("Delete Deployment?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    isActionRunning = true
                    do {
                        try await parentViewModel.deleteDeployment(id: deployment.id)
                        CloudnsToastManager.shared.showSuccess("Deployment Deleted", message: deployment.id)
                        dismiss()
                    } catch {
                        CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                    isActionRunning = false
                }
            }
        } message: {
            Text("Are you sure you want to delete this deployment? This action cannot be undone.")
        }
    }
    
    // MARK: - Terminal View Components
    
    private var buildLogsTerminalView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                // Top Control Bar (Search, Filter, Actions, Quick Jump)
                terminalHeaderToolbar(proxy: proxy)
                
                Divider()
                
                // Terminal Lines View (Scrollable with max height or expanded)
                ScrollView([.vertical, isWrapLogs ? [] : .horizontal], showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 3) {
                        // Top Anchor
                        Color.clear
                            .frame(height: 1)
                            .id("LOG_TOP")
                        
                        if filteredLogs.isEmpty {
                            Text("No logs match the filter criteria.")
                                .font(CloudnsTypography.footnote)
                                .foregroundStyle(.secondary)
                                .padding(CloudnsSpacing.md)
                        } else {
                            ForEach(filteredLogs, id: \.index) { item in
                                HStack(alignment: .top, spacing: CloudnsSpacing.sm) {
                                    // Line Number
                                    Text("\(item.index)")
                                        .font(CloudnsTypography.codeSmall)
                                        .foregroundStyle(.secondary.opacity(0.6))
                                        .frame(width: 32, alignment: .trailing)
                                    
                                    // Line Content
                                    Text(item.log.line)
                                        .font(CloudnsTypography.code)
                                        .foregroundStyle(logColor(item.log.line))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: !isWrapLogs, vertical: false)
                                }
                                .id("LOG_\(item.index)")
                            }
                        }
                        
                        // Bottom Anchor
                        Color.clear
                            .frame(height: 1)
                            .id("LOG_BOTTOM")
                    }
                    .padding(CloudnsSpacing.mdMedium)
                }
                .frame(height: isExpandedLog ? 520 : 360)
            }
            .background(terminalBackground)
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous)
                    .stroke(CloudnsColor.separator, lineWidth: 0.5)
            )
            .listRowInsets(EdgeInsets(top: CloudnsSpacing.xs, leading: 0, bottom: CloudnsSpacing.xs, trailing: 0))
        }
    }
    
    private func terminalHeaderToolbar(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: CloudnsSpacing.xs) {
            // First row: Quick Jump & Utility Actions
            HStack(spacing: CloudnsSpacing.sm) {
                // Filter Picker
                Picker("Filter", selection: $selectedLogFilter) {
                    ForEach(LogFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                
                Spacer()
                
                // Wrap Toggle
                Button {
                    withAnimation(CloudnsAnimation.snappy) {
                        isWrapLogs.toggle()
                    }
                } label: {
                    Image(systemName: isWrapLogs ? "text.word.spacing" : "arrow.left.and.right.text.vertical")
                        .font(CloudnsTypography.caption.weight(.medium))
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xs)
                        .background(isWrapLogs ? CloudnsColor.brandMuted : CloudnsColor.chipBackground)
                        .foregroundStyle(isWrapLogs ? CloudnsColor.brand : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isWrapLogs ? "Disable word wrap" : "Enable word wrap")
                
                // Jump to Top ⬆
                Button {
                    withAnimation(CloudnsAnimation.snappy) {
                        proxy.scrollTo("LOG_TOP", anchor: .top)
                    }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(CloudnsTypography.caption.weight(.medium))
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xs)
                        .background(CloudnsColor.chipBackground)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Jump to top of logs")
                
                // Jump to Bottom ⬇ (Most important for build output!)
                Button {
                    withAnimation(CloudnsAnimation.snappy) {
                        proxy.scrollTo("LOG_BOTTOM", anchor: .bottom)
                    }
                } label: {
                    HStack(spacing: CloudnsSpacing.xxs) {
                        Image(systemName: "arrow.down")
                        Text("End")
                            .font(CloudnsTypography.caption2.weight(.bold))
                    }
                    .padding(.horizontal, CloudnsSpacing.sm)
                    .padding(.vertical, CloudnsSpacing.xs)
                    .background(CloudnsColor.brandMuted)
                    .foregroundStyle(CloudnsColor.brand)
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Jump to latest logs at bottom")
                
                // Copy All Logs
                Button {
                    let fullLog = viewModel.logs.map(\.line).joined(separator: "\n")
                    UIPasteboard.general.string = fullLog
                    HapticManager.notification(.success)
                    CloudnsToastManager.shared.showCopied("Build logs copied to clipboard")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(CloudnsTypography.caption.weight(.medium))
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xs)
                        .background(CloudnsColor.chipBackground)
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Copy all build logs")
            }
            
            // Second row: Search field
            HStack(spacing: CloudnsSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(CloudnsTypography.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Search logs...", text: $logSearchText)
                    .font(CloudnsTypography.codeSmall)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                if !logSearchText.isEmpty {
                    Button {
                        logSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(CloudnsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("\(filteredLogs.count) lines")
                    .font(CloudnsTypography.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, CloudnsSpacing.smMd)
            .padding(.vertical, CloudnsSpacing.xs)
            .background(CloudnsColor.primaryFill.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
        }
        .padding(CloudnsSpacing.smMd)
        .background(CloudnsColor.secondaryGroupedBackground)
    }
    
    private var terminalBackground: Color {
        if colorScheme == .dark {
            return Color(red: 0.09, green: 0.10, blue: 0.12)
        } else {
            return CloudnsColor.secondaryGroupedBackground
        }
    }
    
    private func logColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("error") || lower.contains("failed") || lower.contains("fatal") || lower.contains("exception") {
            return CloudnsColor.danger
        } else if lower.contains("warn") || lower.contains("deprecated") {
            return CloudnsColor.warning
        } else if lower.contains("success") || lower.contains("complete") || lower.contains("done") || lower.contains("built in") {
            return CloudnsColor.success
        } else if line.trimmingCharacters(in: .whitespaces).hasPrefix("$") || lower.contains("npm run") || lower.contains("pnpm") || lower.contains("wrangler") {
            return CloudnsColor.brand
        }
        return colorScheme == .dark ? CloudnsColor.textInverseMuted : CloudnsColor.textPrimary
    }
}
