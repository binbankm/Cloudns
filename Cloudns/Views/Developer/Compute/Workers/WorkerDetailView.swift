import SwiftUI
import UniformTypeIdentifiers

// MARK: - WorkerDetailView
// Apple HIG Compliant Cloudflare Worker Script Architecture, Subdomain & Dispatch Hub

struct WorkerDetailView: View {
    let accountId: String
    let worker: WorkerScript
    @StateObject private var viewModel: WorkerDetailViewModel
    
    init(accountId: String, worker: WorkerScript) {
        self.accountId = accountId
        self.worker = worker
        _viewModel = StateObject(wrappedValue: WorkerDetailViewModel(accountId: accountId, worker: worker))
    }
    
    var body: some View {
        contentView
            .navigationTitle(worker.id)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.fetchDetails()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchDetails()
                }
            }
            .onAppear {
                WidgetDataStore.shared.syncWorkerWithAnalytics(script: worker, accountId: accountId)
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            // MARK: - Hero & Script Overview Card
            Section {
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.md) {
                    HStack(alignment: .top, spacing: HIGTokens.Spacing.md) {
                        Image(systemName: "bolt.fill")
                            .font(HIGTypography.title2)
                            .foregroundStyle(.white)
                            .frame(width: HIGTokens.Size.minTouchTarget, height: HIGTokens.Size.minTouchTarget)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                            .shadow(color: Color.orange.opacity(0.25), radius: 6, x: 0, y: 3)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text(viewModel.worker.id)
                                .font(HIGTypography.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            HStack(spacing: HIGTokens.Spacing.xs) {
                                HIGBadge(.active((viewModel.worker.usageModel ?? "Standard").capitalized), isCompact: true)
                                
                                if !viewModel.modules.isEmpty {
                                    HIGBadge(.custom(color: .purple, text: viewModel.modules.count > 1 ? "\(viewModel.modules.count) ESM Modules" : "ESM Module"), isCompact: true)
                                }
                                
                                if let sub = viewModel.subdomain {
                                    HIGBadge(sub.enabled ? .active("workers.dev") : .custom(color: .secondary, text: "subdomain off"), isCompact: true)
                                }
                            }
                        }
                    }
                    
                    if let sub = viewModel.subdomain {
                        Divider()
                        
                        HStack(spacing: HIGTokens.Spacing.md) {
                            ListRowIcon(icon: "link", color: HIGColors.success, size: 28, cornerRadius: HIGTokens.Radius.sm)
                            
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                Text("workers.dev Subdomain")
                                    .font(HIGTypography.caption2)
                                    .foregroundStyle(.secondary)
                                if sub.enabled {
                                    if let id = sub.id, !id.isEmpty {
                                        Text(id.hasPrefix("http") ? id : "https://\(id)")
                                            .font(HIGTypography.caption.monospaced())
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                    } else {
                                        Text("Enabled (workers.dev)")
                                            .font(HIGTypography.caption.weight(.medium))
                                            .foregroundStyle(HIGColors.success)
                                    }
                                } else {
                                    Text("Disabled")
                                        .font(HIGTypography.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if sub.enabled {
                                if let id = sub.id, !id.isEmpty {
                                    let urlStr = id.hasPrefix("http") ? id : "https://\(id)"
                                    Button {
                                        UIPasteboard.general.string = urlStr
                                        ToastManager.shared.showCopied("Subdomain URL Copied")
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
                                    .higTouchTarget(44)
                                    .accessibilityLabel("Copy Subdomain URL")
                                }
                            }
                            
                            Toggle(isOn: Binding(
                                get: { sub.enabled },
                                set: { val in
                                    Task { await viewModel.toggleSubdomain(enabled: val) }
                                }
                            )) { }
                            .labelsHidden()
                            .disabled(viewModel.isSubdomainUpdating)
                        }
                    }
                }
                .padding(.vertical, HIGTokens.Spacing.xxs)
            }
            
            // MARK: - Script Details
            Section(header: Text("Script Details")) {
                if !viewModel.scriptContent.isEmpty {
                    LabeledContent {
                        Text(verbatim: ByteCountFormatters.format(viewModel.scriptContent.utf8.count))
                            .font(HIGTypography.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } label: {
                        HStack(spacing: HIGTokens.Spacing.md) {
                            ListRowIcon(icon: "doc.zipper", color: .blue)
                            Text("Total Size")
                                .font(HIGTypography.body)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                if let compat = viewModel.worker.compatibilityDate {
                    LabeledContent {
                        Text(compat)
                            .font(HIGTypography.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } label: {
                        HStack(spacing: HIGTokens.Spacing.md) {
                            ListRowIcon(icon: "calendar.badge.clock", color: .orange)
                            Text("Compatibility Date")
                                .font(HIGTypography.body)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                if let modified = viewModel.worker.modifiedOn, let date = DateFormatters.parseISO8601(modified) {
                    LabeledContent {
                        Text(date.displayFormatted(date: .abbreviated, time: .shortened))
                            .font(HIGTypography.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } label: {
                        HStack(spacing: HIGTokens.Spacing.md) {
                            ListRowIcon(icon: "clock.arrow.2.circlepath", color: .purple)
                            Text("Last Modified")
                                .font(HIGTypography.body)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            
            // MARK: - Management Links
            Section(header: Text("Management")) {
                NavigationLink {
                    WorkerAnalyticsView(accountId: accountId, scriptName: worker.id)
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
                    WorkerSourceCodeView(
                        parentViewModel: viewModel,
                        scriptName: worker.id,
                        modules: viewModel.modules,
                        singleScriptContent: viewModel.scriptContent
                    )
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "curlybraces", color: .blue)
                        Text("Source Code")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.scriptContent.isEmpty {
                            Text(verbatim: ByteCountFormatters.format(viewModel.scriptContent.utf8.count))
                                .font(HIGTypography.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerDeploymentsView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "clock.arrow.circlepath", color: .orange)
                        Text("Deployments History")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                NavigationLink {
                    WorkerRoutesView(accountId: accountId, scriptName: worker.id, fallbackRoutes: worker.routes ?? [])
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "globe", color: .blue)
                        Text("Domains & Routes")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if let routes = worker.routes, !routes.isEmpty {
                            Text("\(routes.count)")
                                .font(HIGTypography.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerSecretsView(accountId: accountId, scriptName: worker.id)
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
                    WorkerBindingsView(accountId: accountId, scriptName: worker.id, bindings: viewModel.bindings)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "link.badge.plus", color: .indigo)
                        Text("Resource Bindings")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.bindings.isEmpty {
                            Text("\(viewModel.bindings.count)")
                                .font(HIGTypography.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerTriggersView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "clock", color: .purple)
                        Text("Cron Triggers")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.schedules.isEmpty {
                            Text("\(viewModel.schedules.count)")
                                .font(HIGTypography.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerTailView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "terminal.fill", color: .teal)
                        Text("Real-Time Logs")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
            }
            
            // MARK: - Debugging
            Section(header: Text("Debugging")) {
                NavigationLink {
                    WorkerTestView(scriptName: worker.id, initialRoute: worker.routes?.first)
                } label: {
                    HStack(spacing: HIGTokens.Spacing.md) {
                        ListRowIcon(icon: "play.fill", color: HIGColors.success)
                        Text("Test Dispatch")
                            .font(HIGTypography.body)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
