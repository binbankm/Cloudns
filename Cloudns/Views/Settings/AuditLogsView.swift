import SwiftUI

struct AuditLogsView: View {
    let accountId: String
    @StateObject private var viewModel: AuditLogsViewModel
    @State private var selectedLog: AuditLog?
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AuditLogsViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredLogs.isEmpty {
                Section {
                    ForEach(viewModel.filteredLogs) { log in
                        Button {
                            selectedLog = log
                            HapticManager.impact(.light)
                        } label: {
                            AuditLogRowView(log: log)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Audit Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Actions or Users")
        .refreshable {
            await viewModel.fetchLogs()
        }
        .sheet(item: $selectedLog) { log in
            NavigationStack {
                AuditLogDetailSheet(log: log)
            }
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.logs.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchLogs() } }
                        )
                    )
                } else if viewModel.logs.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "list.clipboard.fill",
                            title: "No Audit Logs",
                            message: "No recent account audit logs or modification records found."
                        )
                    )
                } else if viewModel.filteredLogs.isEmpty && !viewModel.searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchLogs()
            }
        }
    }
}

// MARK: - Audit Log Row View

struct AuditLogRowView: View {
    let log: AuditLog
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(log.actionColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: log.actionIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(log.actionColor)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(log.displayAction)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if let resType = log.resource?.type, !resType.isEmpty {
                        Text(resType)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    if let res = log.action?.result {
                        CloudnsBadge(res ? .active("Success") : .error("Failed"), isCompact: true)
                    }
                }
                
                Text(log.displayResourceTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let email = log.actor?.email, !email.isEmpty {
                        Label(email, systemImage: "person.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if let actorType = log.actor?.type {
                        Text(actorType.uppercased())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let ip = log.actor?.ip, !ip.isEmpty {
                        Text("• \(ip)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let when = log.when {
                        Text(DateFormatters.formatISO8601ToDisplay(when, style: DateFormatters.mediumDateTime))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Audit Log Detail Sheet

struct AuditLogDetailSheet: View {
    let log: AuditLog
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            // MARK: 1. Status & Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(log.actionColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: log.actionIcon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(log.actionColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text(log.displayAction)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text(log.displayResourceTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let res = log.action?.result {
                        CloudnsBadge(res ? .active("Success") : .error("Failed"), isCompact: false)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            
            // MARK: 2. Operation Info
            Section("Operation Summary") {
                detailRow(label: "Action Type", value: log.action?.type ?? "-")
                if let info = log.action?.info, !info.isEmpty {
                    detailRow(label: "Info", value: info)
                }
                if let iface = log.interface, !iface.isEmpty {
                    detailRow(label: "Interface", value: iface)
                }
                if let when = log.when {
                    detailRow(label: "Time (Local)", value: DateFormatters.formatISO8601ToDisplay(when, style: DateFormatters.mediumDateTime))
                    detailRow(label: "Time (UTC)", value: when)
                }
            }
            
            // MARK: 3. Actor Info
            Section("Actor Details") {
                if let email = log.actor?.email, !email.isEmpty {
                    detailRow(label: "Actor Email", value: email, isCopyable: true)
                }
                if let actorType = log.actor?.type, !actorType.isEmpty {
                    detailRow(label: "Actor Type", value: actorType)
                }
                if let actorId = log.actor?.id, !actorId.isEmpty {
                    detailRow(label: "Actor ID", value: actorId, isCopyable: true)
                }
                if let ip = log.actor?.ip, !ip.isEmpty {
                    detailRow(label: "Source IP", value: ip, isCopyable: true)
                }
            }
            
            // MARK: 4. Target Resource
            Section("Target Resource") {
                if let resType = log.resource?.type, !resType.isEmpty {
                    detailRow(label: "Resource Type", value: resType)
                }
                if let resId = log.resource?.id, !resId.isEmpty {
                    detailRow(label: "Resource ID", value: resId, isCopyable: true)
                }
                if let zoneName = log.zone?.name, !zoneName.isEmpty {
                    detailRow(label: "Zone", value: zoneName, isCopyable: true)
                }
                if let zoneId = log.zone?.id, !zoneId.isEmpty {
                    detailRow(label: "Zone ID", value: zoneId, isCopyable: true)
                }
            }
            
            // MARK: 5. Payload / Changes
            if log.oldValue != nil || log.newValue != nil {
                Section("Changes") {
                    if let oldVal = log.oldValue, !oldVal.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Previous Value")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(oldVal)
                                .font(.caption.monospaced())
                                .foregroundStyle(.red)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if let newVal = log.newValue, !newVal.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Value")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(newVal)
                                .font(.caption.monospaced())
                                .foregroundStyle(.green)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            // MARK: 6. Event ID
            Section {
                detailRow(label: "Audit Log ID", value: log.id, isCopyable: true)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Audit Log Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func detailRow(label: LocalizedStringKey, value: String, isCopyable: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 12)
            
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
            
            if isCopyable {
                Button {
                    UIPasteboard.general.string = value
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
