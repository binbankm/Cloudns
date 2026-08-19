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
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            // MARK: - Metadata
            Section(header: Text("Script Overview")) {
                    HStack {
                        Text("Script Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(viewModel.worker.id)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
                    if let sub = viewModel.subdomain {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("workers.dev Subdomain")
                                    .foregroundStyle(.primary)
                                if sub.enabled, let id = sub.id {
                                    Text("https://\(id)")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { sub.enabled },
                                set: { val in
                                    Task { await viewModel.toggleSubdomain(enabled: val) }
                                }
                            ))
                            .disabled(viewModel.isSubdomainUpdating)
                        }
                    }
                    
                    if !viewModel.modules.isEmpty {
                        HStack {
                            Text("Modules")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.modules.count > 1 ? "\(viewModel.modules.count) Modules (ESM)" : "1 Module")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if !viewModel.scriptContent.isEmpty {
                        HStack {
                            Text("Total Size")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatBytes(viewModel.scriptContent.utf8.count))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if let usage = viewModel.worker.usageModel {
                        HStack {
                            Text("Usage Model")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(usage.capitalized)
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if let compat = viewModel.worker.compatibilityDate {
                        HStack {
                            Text("Compatibility Date")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(compat)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if let modified = viewModel.worker.modifiedOn {
                        HStack {
                            Text("Last Modified")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(DateFormatters.formatISO8601ToDisplay(modified))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                // MARK: - Management Links
                Section(header: Text("Management")) {
                    NavigationLink {
                        WorkerSourceCodeView(
                            parentViewModel: viewModel,
                            scriptName: worker.id,
                            modules: viewModel.modules,
                            singleScriptContent: viewModel.scriptContent
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "curlybraces")
                                .font(.body)
                                .foregroundStyle(.purple)
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
                        WorkerRoutesView(accountId: accountId, scriptName: worker.id, fallbackRoutes: worker.routes ?? [])
                    } label: {
                        HStack(spacing: 12) {
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
                        HStack(spacing: 12) {
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
                        HStack(spacing: 12) {
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
                        HStack(spacing: 12) {
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
                    
                    NavigationLink {
                        WorkerAnalyticsView(accountId: accountId, scriptName: worker.id)
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
                
                // MARK: - Debugging
                Section(header: Text("Debugging")) {
                    NavigationLink {
                        WorkerTestView(scriptName: worker.id, initialRoute: worker.routes?.first)
                    } label: {
                        HStack(spacing: 12) {
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
