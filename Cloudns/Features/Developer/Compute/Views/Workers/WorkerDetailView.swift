import SwiftUI
import UniformTypeIdentifiers

struct WorkerDetailView: View {
    // MARK: - Properties
    let accountId: String
    let worker: WorkerScript
    @StateObject private var viewModel: WorkerDetailViewModel
    
    init(accountId: String, worker: WorkerScript) {
        self.accountId = accountId
        self.worker = worker
        _viewModel = StateObject(wrappedValue: WorkerDetailViewModel(accountId: accountId, worker: worker))
    }
    
    // MARK: - Body
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
    // MARK: - Private Views
    private var contentView: some View {
        List {
            // MARK: - Hero & Script Overview Card
            Section {
                VStack(alignment: .leading, spacing: CloudnsSpacing.mdMedium) {
                    HStack(alignment: .top, spacing: CloudnsSpacing.mdMedium) {
                        Image(systemName: "bolt.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: CloudnsSize.minTouchTarget, height: CloudnsSize.minTouchTarget)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
                            .cloudnsShadow(.brand(color: CloudnsColor.brandAccent, radius: 6, y: 3))
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                            Text(viewModel.worker.id)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            HStack(spacing: CloudnsSpacing.sm) {
                                CloudnsBadge(.active((viewModel.worker.usageModel ?? "Standard").capitalized), isCompact: true)
                                
                                if !viewModel.modules.isEmpty {
                                    CloudnsBadge(.custom(color: .purple, text: viewModel.modules.count > 1 ? "\(viewModel.modules.count) ESM Modules" : "ESM Module"), isCompact: true)
                                }
                                
                                if let sub = viewModel.subdomain {
                                    CloudnsBadge(sub.enabled ? .active("workers.dev") : .custom(color: .secondary, text: "subdomain off"), isCompact: true)
                                }
                            }
                        }
                    }
                    
                    if let sub = viewModel.subdomain {
                        Divider()
                        
                        HStack(spacing: CloudnsSpacing.smMd) {
                            Image(systemName: "link")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
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
                                        HapticManager.notification(.success)
                                        CloudnsToastManager.shared.showSuccess("URL Copied", message: urlStr)
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: CloudnsSize.avatarSmall, height: CloudnsSize.avatarSmall)
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
                .padding(.vertical, CloudnsSpacing.xs)
            }
            
            // MARK: - Script Details
            Section(header: Text("Script Details")) {
                if !viewModel.scriptContent.isEmpty {
                    HStack {
                        Label {
                            Text("Total Size")
                        } icon: {
                            Image(systemName: "doc.zipper")
                                .foregroundStyle(.blue)
                        }
                        .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text(formatBytes(viewModel.scriptContent.utf8.count))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let compat = viewModel.worker.compatibilityDate {
                    HStack {
                        Label {
                            Text("Compatibility Date")
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.orange)
                        }
                        .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text(compat)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let modified = viewModel.worker.modifiedOn {
                    HStack {
                        Label {
                            Text("Last Modified")
                        } icon: {
                            Image(systemName: "clock.arrow.2.circlepath")
                                .foregroundStyle(.purple)
                        }
                        .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text(DateFormatters.formatISO8601ToDisplay(modified))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // MARK: - Management Links
            Section(header: Text("Management")) {
                NavigationLink {
                    WorkerAnalyticsView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: CloudnsSpacing.mdSmall) {
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
                
                NavigationLink {
                    WorkerSourceCodeView(
                        parentViewModel: viewModel,
                        scriptName: worker.id,
                        modules: viewModel.modules,
                        singleScriptContent: viewModel.scriptContent
                    )
                } label: {
                    HStack(spacing: CloudnsSpacing.mdSmall) {
                        Image(systemName: "curlybraces")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Source Code")
                            .foregroundStyle(.primary)
                        Spacer()
                        if !viewModel.scriptContent.isEmpty {
                            Text(formatBytes(viewModel.scriptContent.utf8.count))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                NavigationLink {
                    WorkerDeploymentsView(accountId: accountId, scriptName: worker.id)
                } label: {
                    HStack(spacing: CloudnsSpacing.mdSmall) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Deployments History")
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
                
                NavigationLink {
                    WorkerRoutesView(accountId: accountId, scriptName: worker.id, fallbackRoutes: worker.routes ?? [])
                } label: {
                    HStack(spacing: CloudnsSpacing.mdSmall) {
                        Image(systemName: "globe")
                            .font(.body)
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                            .accessibilityHidden(true)
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
                    WorkerBindingsView(accountId: accountId, scriptName: worker.id, bindings: viewModel.bindings)
                } label: {
                    HStack(spacing: CloudnsSpacing.mdSmall) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body)
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Bindings & Variables")
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
                    HStack(spacing: CloudnsSpacing.mdSmall) {
                        Image(systemName: "clock")
                            .font(.body)
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                            .accessibilityHidden(true)
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
                    HStack(spacing: CloudnsSpacing.mdSmall) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.body)
                            .foregroundStyle(.green)
                            .frame(width: 24)
                            .accessibilityHidden(true)
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
                        HStack(spacing: CloudnsSpacing.mdSmall) {
                            Image(systemName: "paperplane.fill")
                                .font(.body)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text("Test Dispatch")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .centerConstrainedWidth(maxWidth: 840)
    }
    
    // MARK: - Actions
    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.2f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
}
