import SwiftUI

// MARK: - AuditLogsView

struct AuditLogsView: View {
    let accountId: String
    @StateObject private var viewModel: AuditLogsViewModel
    @State private var selectedLog: AuditLog?
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    
    init(accountId: String = "") {
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
                            HapticManager.selection()
                        } label: {
                            AuditLogRowView(log: log)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Logs"
        )
        .navigationTitle("Audit Logs")
        .navigationBarTitleDisplayMode(.inline)
        .id(appLanguage)
        .refreshable {
            await viewModel.fetchLogs()
        }
        .sheet(item: $selectedLog) { log in
            NavigationStack {
                AuditLogDetailSheetView(log: log)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Audit Logs…",
            error: viewModel.logs.isEmpty ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && viewModel.logs.isEmpty,
            empty: EmptyStateConfig(
                title: "No Audit Logs",
                systemImage: "list.clipboard.fill",
                description: "No recent account audit logs or modification records found."
            ),
            searchQuery: (viewModel.hasFetchedData && viewModel.filteredLogs.isEmpty && !viewModel.searchText.isEmpty) ? viewModel.searchText : nil,
            onRetry: { Task { await viewModel.fetchLogs() } }
        )
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchLogs()
            }
        }
    }
}

// MARK: - AuditLogRowView (Inlined & Cohesive)

struct AuditLogRowView: View {
    let log: AuditLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(log.actionColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: log.actionIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(log.actionColor)
            }
            .accessibilityHidden(true)
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(LocalizedStringKey(log.displayActionKey))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text(LocalizedStringKey(log.friendlyResourceTypeKey))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if let res = log.action?.result {
                        Text(res ? "Success" : "Failed")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(res ? Color.green : Color.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(res ? Color.green.opacity(0.12) : Color.red.opacity(0.12)))
                    }
                }
                
                log.primarySummaryView
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                log.secondaryContextView
                
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
                    
                    if let when = log.when, let date = DateFormatters.parseISO8601(when) {
                        Text(date.displayFormatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

// MARK: - AuditLogDetailSheetView (Inlined & Cohesive)

struct AuditLogDetailSheetView: View {
    let log: AuditLog
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(log.actionColor.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: log.actionIcon)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(log.actionColor)
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text(LocalizedStringKey(log.displayActionKey))
                            Text("•")
                            Text(LocalizedStringKey(log.friendlyResourceTypeKey))
                        }
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        
                        log.primarySummaryView
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let res = log.action?.result {
                        Text(res ? "Success" : "Failed")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(res ? Color.green : Color.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(res ? Color.green.opacity(0.12) : Color.red.opacity(0.12)))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            
            Section("Operation Summary") {
                detailRow(label: "Action Type", value: log.action?.type ?? "-")
                if let info = log.action?.info, !info.isEmpty {
                    detailRow(label: "Action Info", value: info)
                }
                if let iface = log.interface, !iface.isEmpty {
                    detailRow(label: "Interface", value: iface)
                }
                if let when = log.when {
                    if let date = DateFormatters.parseISO8601(when) {
                        HStack {
                            Text("Time (Local)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(date.displayFormatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                    detailRow(label: "Time (UTC)", value: when)
                }
            }
            
            if hasChanges {
                Section("Changes & Payload") {
                    if let oldText = formattedOldValue, !oldText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Previous Value (Before)", systemImage: "minus.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.red)
                            Text(oldText)
                                .font(.caption.monospaced())
                                .foregroundStyle(.primary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if let newText = formattedNewValue, !newText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("New Value (After)", systemImage: "plus.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.green)
                            Text(newText)
                                .font(.caption.monospaced())
                                .foregroundStyle(.primary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            if let meta = log.metadata, !meta.isEmpty {
                Section("Metadata & Context") {
                    ForEach(Array(meta.keys.sorted()), id: \.self) { key in
                        if let val = meta[key] {
                            detailRow(verbatimLabel: key, value: val.description, isCopyable: true)
                        }
                    }
                }
            }
            
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
            
            Section {
                detailRow(label: "Audit Log ID", value: log.id, isCopyable: true)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Audit Log Detail")
        .navigationBarTitleDisplayMode(.inline)
        .presentationDragIndicator(.visible)
        .id(appLanguage)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private var hasChanges: Bool {
        return formattedOldValue != nil || formattedNewValue != nil
    }
    
    private var formattedOldValue: String? {
        if let json = log.oldValueJson, !json.isEmpty {
            let val = AnyJSONValue.dictionary(json)
            return val.prettyJSONString
        }
        if let old = log.oldValue, old != .null && old != .string("") {
            return old.prettyJSONString
        }
        return nil
    }
    
    private var formattedNewValue: String? {
        if let json = log.newValueJson, !json.isEmpty {
            let val = AnyJSONValue.dictionary(json)
            return val.prettyJSONString
        }
        if let new = log.newValue, new != .null && new != .string("") {
            return new.prettyJSONString
        }
        return nil
    }
    
    private func detailRow(label: LocalizedStringKey, value: String, isCopyable: Bool = false) -> some View {
        detailRowContent(labelView: Text(label), value: value, isCopyable: isCopyable)
    }
    
    private func detailRow(verbatimLabel: String, value: String, isCopyable: Bool = false) -> some View {
        detailRowContent(labelView: Text(verbatim: verbatimLabel), value: value, isCopyable: isCopyable)
    }
    
    private func detailRowContent<V: View>(labelView: V, value: String, isCopyable: Bool) -> some View {
        HStack {
            labelView
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 12)
            
            Text(verbatim: value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
            
            if isCopyable {
                Button {
                    copyToClipboard(value, toast: "Copied")
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
