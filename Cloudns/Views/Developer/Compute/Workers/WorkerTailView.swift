import SwiftUI

// MARK: - WorkerTailView
// Apple HIG Compliant Cloudflare Worker WebSocket Live Tail Log Streamer

struct WorkerTailView: View {
    let accountId: String
    let scriptName: String
    
    @StateObject private var viewModel: WorkerTailViewModel
    @State private var selectedEvent: TailTraceItem?
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerTailViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            filterBar
                .padding(.horizontal, HIGTokens.Spacing.md)
                .padding(.vertical, HIGTokens.Spacing.sm)
                .background(Color(.secondarySystemGroupedBackground))
            
            Divider()
            
            if viewModel.events.isEmpty {
                emptyState
            } else {
                ScrollViewReader { _ in
                    List {
                        ForEach(viewModel.filteredEvents) { item in
                            Button {
                                HIGFeedback.selection()
                                selectedEvent = item
                            } label: {
                                TailEventRowView(item: item)
                            }
                            .listRowInsets(EdgeInsets(top: HIGTokens.Spacing.sm, leading: HIGTokens.Spacing.md, bottom: HIGTokens.Spacing.sm, trailing: HIGTokens.Spacing.md))
                            .listRowBackground(Color(.systemBackground))
                            .contextMenu {
                                if let url = item.event?.request?.url {
                                    Button {
                                        UIPasteboard.general.string = url
                                        ToastManager.shared.showCopied("URL Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Request URL", systemImage: "doc.on.doc")
                                    }
                                }
                                if let outcome = item.outcome {
                                    Button {
                                        UIPasteboard.general.string = outcome
                                        ToastManager.shared.showCopied("Outcome Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Outcome", systemImage: "flag")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Logs & URLs"
        )
        .navigationTitle("Live Tail Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Button {
                        HIGFeedback.impact(.light)
                        viewModel.clearLogs()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear Logs")
                    .disabled(viewModel.events.isEmpty)
                    .higTouchTarget(44)
                    
                    Button {
                        HIGFeedback.impact(.light)
                        if viewModel.isStreaming {
                            viewModel.stopStream()
                        } else {
                            Task { await viewModel.startStream() }
                        }
                    } label: {
                        Image(systemName: viewModel.isStreaming ? "pause.fill" : "play.fill")
                            .foregroundStyle(viewModel.isStreaming ? .orange : HIGColors.success)
                    }
                    .accessibilityLabel(viewModel.isStreaming ? "Pause Stream" : "Resume Stream")
                    .higTouchTarget(44)
                }
            }
        }
        .task {
            await viewModel.startStream()
        }
        .onDisappear {
            viewModel.stopStream()
        }
        .sheet(item: $selectedEvent) { event in
            TailEventDetailSheetView(event: event)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .higToast()
        }
    }
    
    private var filterBar: some View {
        HStack(spacing: HIGTokens.Spacing.md) {
            HStack(spacing: HIGTokens.Spacing.xs) {
                Circle()
                    .fill(viewModel.isStreaming ? HIGColors.success : HIGColors.error)
                    .frame(width: 8, height: 8)
                Text(viewModel.isStreaming ? "Connected" : "Paused")
                    .font(HIGTypography.caption.weight(.medium))
                    .foregroundStyle(viewModel.isStreaming ? HIGColors.success : .secondary)
            }
            
            Spacer()
            
            Picker("Filter", selection: $viewModel.selectedFilter) {
                Text("All (\(viewModel.events.count))").tag(0)
                Text("Logs").tag(1)
                Text("Exceptions").tag(2)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)
            .onChange(of: viewModel.selectedFilter) { _ in
                HIGFeedback.selection()
            }
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        if viewModel.isStreaming {
            HIGContentState(
                .loading(message: "Listening for live Worker events…")
            )
        } else {
            HIGContentState(
                .empty(
                    title: "Log Stream Paused",
                    systemImage: "pause.circle",
                    description: "Stream is paused. Tap Resume to start listening for live edge execution events.",
                    actionTitle: "Resume Stream",
                    action: {
                        HIGFeedback.impact(.light)
                        Task { await viewModel.startStream() }
                    }
                )
            )
        }
    }
}

// MARK: - TailEventRowView (Inlined & Cohesive)

struct TailEventRowView: View {
    let item: TailTraceItem
    
    private var outcomeColor: Color {
        switch item.outcome?.lowercased() {
        case "ok": return HIGColors.success
        case "exception": return HIGColors.error
        case "canceled": return .orange
        default: return .secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack {
                if let method = item.event?.request?.method {
                    Text(method)
                        .font(HIGTypography.caption2.bold())
                        .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                } else if item.event?.cron != nil {
                    Text("CRON")
                        .font(HIGTypography.caption2.bold())
                        .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                }
                
                if let url = item.event?.request?.url {
                    Text(url)
                        .font(HIGTypography.caption.monospaced())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let outcome = item.outcome {
                    HIGBadge(.custom(color: outcomeColor, text: outcome.uppercased()), isCompact: true)
                }
            }
            
            if let logs = item.logs, !logs.isEmpty {
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                    ForEach(logs.prefix(2)) { log in
                        let logText = (log.message ?? []).map(\.displayText).joined(separator: " ")
                        Text(logText)
                            .font(HIGTypography.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            if let exceptions = item.exceptions, !exceptions.isEmpty {
                ForEach(exceptions) { ex in
                    Text(ex.message ?? "Unhandled Exception")
                        .font(HIGTypography.caption2.monospaced())
                        .foregroundStyle(HIGColors.error)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}

// MARK: - TailEventDetailSheetView (Inlined & Cohesive)

struct TailEventDetailSheetView: View {
    let event: TailTraceItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Event Overview")) {
                    if let outcome = event.outcome {
                        LabeledContent("Outcome", value: outcome.capitalized)
                    }
                    if let method = event.event?.request?.method {
                        LabeledContent("HTTP Method", value: method)
                    }
                    if let url = event.event?.request?.url {
                        LabeledContent("URL", value: url)
                    }
                    if let cron = event.event?.cron {
                        LabeledContent("Cron Schedule", value: cron)
                    }
                }
                
                if let logs = event.logs, !logs.isEmpty {
                    Section(header: Text("Console Logs (\(logs.count))")) {
                        ForEach(logs) { log in
                            let levelText = log.level?.uppercased() ?? "LOG"
                            let isErr = log.level == "error"
                            let logText = (log.message ?? []).map(\.displayText).joined(separator: " ")
                            
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                HStack {
                                    Text(levelText)
                                        .font(HIGTypography.caption2.bold())
                                        .foregroundStyle(isErr ? HIGColors.error : .blue)
                                    Spacer()
                                }
                                Text(logText)
                                    .font(HIGTypography.caption.monospaced())
                            }
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                        }
                    }
                }
                
                if let exceptions = event.exceptions, !exceptions.isEmpty {
                    Section(header: Text("Exceptions (\(exceptions.count))")) {
                        ForEach(exceptions) { ex in
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                Text(ex.name ?? "Exception")
                                    .font(HIGTypography.caption.bold())
                                    .foregroundStyle(HIGColors.error)
                                if let msg = ex.message, !msg.isEmpty {
                                    Text(verbatim: msg)
                                        .font(HIGTypography.caption2.monospaced())
                                }
                            }
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .higTouchTarget(44)
                }
            }
        }
    }
}
