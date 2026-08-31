import SwiftUI
import UniformTypeIdentifiers

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
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "bolt.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Color.orange.opacity(0.25), radius: 6, x: 0, y: 3)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.worker.id)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            HStack(spacing: 6) {
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
                        
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "link", color: .green, size: 28, cornerRadius: 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("workers.dev Subdomain")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if sub.enabled {
                                    if let id = sub.id, !id.isEmpty {
                                        Text(id.hasPrefix("http") ? id : "https://\(id)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                    } else {
                                        Text("Enabled (workers.dev)")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.green)
                                    }
                                } else {
                                    Text("Disabled")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if sub.enabled {
                                if let id = sub.id, !id.isEmpty {
                                    let urlStr = id.hasPrefix("http") ? id : "https://\(id)"
                                    Button {
                                        UIPasteboard.general.string = urlStr
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
                .padding(.vertical, 4)
            }
            
            // MARK: - Script Details
            Section(header: Text("Script Details")) {
                if !viewModel.scriptContent.isEmpty {
                    LabeledContent {
                        Text(verbatim: formatBytes(viewModel.scriptContent.utf8.count))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } label: {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "doc.zipper", color: .blue)
                            Text("Total Size")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                if let compat = viewModel.worker.compatibilityDate {
                    LabeledContent {
                        Text(compat)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } label: {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "calendar.badge.clock", color: .orange)
                            Text("Compatibility Date")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                if let modified = viewModel.worker.modifiedOn, let date = DateFormatters.parseISO8601(modified) {
                    LabeledContent {
                        Text(date, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } label: {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "clock.arrow.2.circlepath", color: .purple)
                            Text("Last Modified")
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
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "chart.xyaxis.line", color: .purple)
                        Text("Analytics & Metrics")
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
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "curlybraces", color: .blue)
                        Text("Source Code")
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.scriptContent.isEmpty {
                            Text(verbatim: formatBytes(viewModel.scriptContent.utf8.count))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerDeploymentsView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "clock.arrow.circlepath", color: .orange)
                        Text("Deployments History")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                NavigationLink {
                    WorkerRoutesView(accountId: accountId, scriptName: worker.id, fallbackRoutes: worker.routes ?? [])
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "globe", color: .blue)
                        Text("Domains & Routes")
                            .foregroundStyle(.primary)
                        Spacer()
                        if let routes = worker.routes, !routes.isEmpty {
                            Text("\(routes.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerSecretsView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "key.fill", color: .green)
                        Text("Variables & Secrets")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                NavigationLink {
                    WorkerBindingsView(accountId: accountId, scriptName: worker.id, bindings: viewModel.bindings)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "link.badge.plus", color: .indigo)
                        Text("Resource Bindings")
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.bindings.isEmpty {
                            Text("\(viewModel.bindings.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerTriggersView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "clock", color: .purple)
                        Text("Cron Triggers")
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.schedules.isEmpty {
                            Text("\(viewModel.schedules.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerTailView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "terminal.fill", color: .teal)
                        Text("Real-Time Logs")
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
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "play.fill", color: .green)
                            Text("Test Dispatch")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        return ByteCountFormatters.format(Int64(bytes))
    }
}
