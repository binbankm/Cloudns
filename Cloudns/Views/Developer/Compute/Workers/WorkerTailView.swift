import SwiftUI

// MARK: - WorkerTailView

struct WorkerTailView: View {
    let accountId: String
    let scriptName: String
    
    @StateObject private var viewModel: WorkerTailViewModel
    @State private var autoScroll = true
    @State private var selectedEvent: TailTraceItem?
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerTailViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            filterBar
                .padding(.horizontal)
                .padding(.vertical, 8)
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
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(Color(.systemBackground))
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
                HStack(spacing: 12) {
                    Button {
                        HIGFeedback.impact(.light)
                        viewModel.clearLogs()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear Logs")
                    .disabled(viewModel.events.isEmpty)
                    
                    Button {
                        HIGFeedback.impact(.light)
                        if viewModel.isStreaming {
                            viewModel.stopStream()
                        } else {
                            Task { await viewModel.startStream() }
                        }
                    } label: {
                        Image(systemName: viewModel.isStreaming ? "pause.fill" : "play.fill")
                            .foregroundStyle(viewModel.isStreaming ? .orange : .green)
                    }
                    .accessibilityLabel(viewModel.isStreaming ? "Pause Stream" : "Resume Stream")
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
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isStreaming ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(viewModel.isStreaming ? "Connected" : "Paused")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.isStreaming ? .green : .secondary)
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
        case "ok": return .green
        case "exception": return .red
        case "canceled": return .orange
        default: return .secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let method = item.event?.request?.method {
                    Text(method)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                } else if item.event?.cron != nil {
                    Text("CRON")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                
                if let url = item.event?.request?.url {
                    Text(url)
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let outcome = item.outcome {
                    HIGBadge(.custom(color: outcomeColor, text: outcome.uppercased()), isCompact: true)
                }
            }
            
            if let logs = item.logs, !logs.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(logs.prefix(2)) { log in
                        let logText = (log.message ?? []).map(\.displayText).joined(separator: " ")
                        Text(logText)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            if let exceptions = item.exceptions, !exceptions.isEmpty {
                ForEach(exceptions) { ex in
                    Text(ex.message ?? "Unhandled Exception")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
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
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(levelText)
                                        .font(.caption2.bold())
                                        .foregroundStyle(isErr ? .red : .blue)
                                    Spacer()
                                }
                                Text(logText)
                                    .font(.caption.monospaced())
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                if let exceptions = event.exceptions, !exceptions.isEmpty {
                    Section(header: Text("Exceptions (\(exceptions.count))")) {
                        ForEach(exceptions) { ex in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ex.name ?? "Exception")
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                                if let msg = ex.message, !msg.isEmpty {
                                    Text(verbatim: msg)
                                        .font(.caption2.monospaced())
                                }
                            }
                            .padding(.vertical, 2)
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
                }
            }
        }
    }
}
