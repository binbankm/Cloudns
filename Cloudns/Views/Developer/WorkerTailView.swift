import SwiftUI

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
            // Top Toolbar: Status & Filters
            filterBar
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
            
            Divider()
            
            // Console Logs Stream
            if viewModel.events.isEmpty {
                emptyState
            } else {
                ScrollViewReader { _ in
                    List {
                        ForEach(viewModel.filteredEvents) { item in
                            Button {
                                HapticManager.impact(.light)
                                selectedEvent = item
                            } label: {
                                TailEventRow(item: item)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(Color(.systemBackground))
                        }
                    }
                    .listStyle(.plain)
                    .centerConstrainedWidth(maxWidth: 840)
                }
            }
        }
        .navigationTitle("Live Tail Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search logs & URLs")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        HapticManager.impact(.light)
                        viewModel.clearLogs()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear logs")
                    .disabled(viewModel.events.isEmpty)
                    
                    Button {
                        HapticManager.impact(.light)
                        if viewModel.isStreaming {
                            viewModel.stopStream()
                        } else {
                            Task { await viewModel.startStream() }
                        }
                    } label: {
                        Image(systemName: viewModel.isStreaming ? "pause.fill" : "play.fill")
                            .foregroundStyle(viewModel.isStreaming ? .orange : .green)
                    }
                    .accessibilityLabel(viewModel.isStreaming ? "Pause stream" : "Resume stream")
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
            TailEventDetailSheet(event: event)
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
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 220)
            .onChange(of: viewModel.selectedFilter) { _ in
                HapticManager.impact(.light)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            if viewModel.isStreaming {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Listening for live worker events…")
                    .font(.body.weight(.medium))
                Text("Send an HTTP request or wait for a cron trigger to see logs appear in real time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Image(systemName: "pause.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("Log stream paused")
                    .font(.body.weight(.medium))
                Button("Resume Stream") {
                    HapticManager.impact(.light)
                    Task { await viewModel.startStream() }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Tail Event Row

private struct TailEventRow: View {
    let item: TailTraceItem
    
    var isOk: Bool { item.outcome == "ok" }
    var timestampStr: String {
        guard let ts = item.eventTimestamp else { return "" }
        return DateFormatters.formatTimestampMs(Double(ts))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Method or Cron badge
                if let method = item.event?.request?.method {
                    Text(method)
                        .font(.caption.monospaced().weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(methodColor(method).opacity(0.15))
                        .foregroundStyle(methodColor(method))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else if let cron = item.event?.cron {
                    Label(cron, systemImage: "clock")
                        .font(.caption.monospaced())
                        .foregroundStyle(.purple)
                }
                
                // Outcome
                CloudnsBadge(isOk ? .active("OK") : .error((item.outcome ?? "Error").uppercased()), isCompact: true)
                
                Spacer()
                
                Text(timestampStr)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            
            // URL
            if let url = item.event?.request?.url {
                Text(url)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            
            // Logs preview
            if let logs = item.logs, !logs.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(logs.prefix(3)) { log in
                        HStack(alignment: .top, spacing: 6) {
                            Text(log.level?.uppercased() ?? "LOG")
                                .font(.caption2.monospaced().weight(.bold))
                                .foregroundStyle(logLevelColor(log.level))
                            
                            let msg = log.message?.map(\.displayText).joined(separator: " ") ?? ""
                            Text(msg)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    if logs.count > 3 {
                        Text("+ \(logs.count - 3) more log lines")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Exceptions preview
            if let exceptions = item.exceptions, !exceptions.isEmpty {
                ForEach(exceptions) { ex in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                        Text(ex.message ?? ex.name ?? "Exception occurred")
                            .font(.caption.monospaced())
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .purple
        }
    }
    
    private func logLevelColor(_ level: String?) -> Color {
        switch level?.lowercased() {
        case "error": return .red
        case "warn": return .orange
        case "info": return .blue
        default: return .secondary
        }
    }
}

// MARK: - Tail Event Detail Sheet

private struct TailEventDetailSheet: View {
    let event: TailTraceItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Event Info")) {
                    if let outcome = event.outcome {
                        LabeledContent("Outcome", value: outcome)
                    }
                    if let method = event.event?.request?.method {
                        LabeledContent("Method", value: method)
                    }
                    if let url = event.event?.request?.url {
                        LabeledContent("URL") {
                            Text(url).font(.footnote.monospaced())
                        }
                    }
                    if let cron = event.event?.cron {
                        LabeledContent("Cron Trigger", value: cron)
                    }
                }
                
                if let logs = event.logs, !logs.isEmpty {
                    Section(header: Text("Console Logs (\(logs.count))")) {
                        ForEach(logs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(log.level?.uppercased() ?? "LOG")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.blue)
                                let msg = log.message?.map(\.displayText).joined(separator: " ") ?? ""
                                Text(msg)
                                    .font(.footnote.monospaced())
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                if let exceptions = event.exceptions, !exceptions.isEmpty {
                    Section(header: Text("Exceptions (\(exceptions.count))")) {
                        ForEach(exceptions) { ex in
                            VStack(alignment: .leading, spacing: 4) {
                                if let name = ex.name {
                                    Text(name).font(.caption).foregroundStyle(.red)
                                }
                                if let msg = ex.message {
                                    Text(msg).font(.footnote.monospaced()).foregroundStyle(.red)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .toastContainer()
        }
    }
}
