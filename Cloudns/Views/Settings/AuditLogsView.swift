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

    static func displayActionBadge(_ key: String) -> Text {
        Text(LocalizedStringKey(key))
    }

    static func friendlyResourceBadge(_ key: String) -> Text {
        Text(LocalizedStringKey(key))
    }
}

// MARK: - AuditLogRowView (Inlined & Cohesive)

struct AuditLogRowView: View {
    let log: AuditLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ListRowIcon(icon: log.actionIcon, color: log.actionColor, size: 34, cornerRadius: 8)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    AuditLogsView.displayActionBadge(log.displayActionKey)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    AuditLogsView.friendlyResourceBadge(log.friendlyResourceTypeKey)
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
                    HeroHeaderEmblemView(icon: log.actionIcon, primaryColor: log.actionColor, size: 56)

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            AuditLogsView.displayActionBadge(log.displayActionKey)
                            Text("•")
                            AuditLogsView.friendlyResourceBadge(log.friendlyResourceTypeKey)
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
        formattedOldValue != nil || formattedNewValue != nil
    }

    private var formattedOldValue: String? {
        if let json = log.oldValueJson, !json.isEmpty {
            let val = AnyJSONValue.dictionary(json)
            return val.prettyJSONString
        }
        if let old = log.oldValue, old != .null, old != .string("") {
            return old.prettyJSONString
        }
        return nil
    }

    private var formattedNewValue: String? {
        if let json = log.newValueJson, !json.isEmpty {
            let val = AnyJSONValue.dictionary(json)
            return val.prettyJSONString
        }
        if let new = log.newValue, new != .null, new != .string("") {
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

    private func detailRowContent(labelView: some View, value: String, isCopyable: Bool) -> some View {
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

// MARK: - View Presentation Extension

@MainActor
extension AuditLog {
    var actionColor: Color {
        let raw = (action?.type ?? action?.info ?? "").lowercased()
        if raw.contains("resume") || raw.contains("unpause") {
            return .green
        } else if raw.contains("pause") {
            return .orange
        } else if raw.contains("create") || raw.contains("add") || raw.contains("insert") {
            return .green
        } else if raw.contains("delete") || raw.contains("remove") || raw.contains("drop") {
            return .red
        } else if raw.contains("deploy") || raw.contains("publish") {
            return .purple
        } else if raw.contains("order") {
            return .orange
        } else if raw.contains("update") || raw.contains("edit") || raw.contains("set") || raw.contains("modify") {
            return .blue
        } else if raw.contains("purge") || raw.contains("clear") {
            return .cyan
        } else if raw.contains("rollback") {
            return .brown
        }
        return .secondary
    }

    @ViewBuilder
    public var primarySummaryView: some View {
        let resType = (resource?.type ?? "").lowercased()
        let actType = (action?.type ?? action?.info ?? "").lowercased()

        if actType.contains("resume") || actType.contains("unpause") {
            let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue ?? metadata?["domain"]?.stringValue
            if let z = zoneName, !z.isEmpty {
                Text("\(z) • Resume Site Proxy")
            } else if let resId = resource?.id, !resId.isEmpty {
                Text("Resume Site Service (ID: \(shortId(resId)))")
            } else {
                Text("Resume Cloudflare Acceleration")
            }
        } else if actType.contains("pause") {
            let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue ?? metadata?["domain"]?.stringValue
            if let z = zoneName, !z.isEmpty {
                Text("\(z) • Pause Site Proxy")
            } else if let resId = resource?.id, !resId.isEmpty {
                Text("Pause Site Service (ID: \(shortId(resId)))")
            } else {
                Text("Pause Cloudflare Acceleration")
            }
        } else if resType.contains("dns") {
            let recordType = extractString(keys: ["type", "record_type", "rec_type"])
            let recordName = extractString(keys: ["name", "record_name", "rec_name"])
            let content = extractString(keys: ["content", "value", "target", "ip"])
            let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue

            if let type = recordType, let name = recordName ?? zoneName, let c = content {
                Text(verbatim: "\(type) Record • \(name) ➔ \(c)")
            } else if let name = recordName ?? zoneName {
                Text(verbatim: name)
            } else {
                AuditLogsView.friendlyResourceBadge(friendlyResourceTypeKey)
            }
        } else if resType.contains("iplist") || resType.contains("ip") {
            let ipVal = extractString(keys: ["ip", "value", "item_value", "redirect_url"])
            let listName = extractString(keys: ["list_name", "name", "title"])
            let comment = extractString(keys: ["comment", "description"])

            if let ip = ipVal, !ip.isEmpty {
                if let name = listName, !name.isEmpty {
                    Text(verbatim: "\(name) • \(ip)")
                } else {
                    Text(verbatim: "IP List Item: \(ip)")
                }
            } else if let name = listName, !name.isEmpty {
                Text(verbatim: name)
            } else if let com = comment, !com.isEmpty {
                Text(verbatim: com)
            } else {
                AuditLogsView.friendlyResourceBadge(friendlyResourceTypeKey)
            }
        } else if resType.contains("zone") || resType.contains("setting") {
            let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue
            let settingKey = extractString(keys: ["setting_id", "setting_name", "id", "name"])
            let val = extractString(keys: ["value", "mode", "status"])
            let sKey = translateSettingKey(settingKey)
            let vKey = translateSettingValue(val)

            if let z = zoneName, !z.isEmpty {
                if let s = sKey, let v = vKey {
                    Text(verbatim: "\(z) • \(s): \(v)")
                } else if let s = sKey {
                    Text(verbatim: "\(z) • \(s)")
                } else {
                    Text(verbatim: z)
                }
            } else if let s = sKey {
                if let v = vKey {
                    Text(verbatim: "\(s): \(v)")
                } else {
                    Text(verbatim: s)
                }
            } else {
                AuditLogsView.friendlyResourceBadge(friendlyResourceTypeKey)
            }
        } else if resType.contains("worker") || resType.contains("page") {
            let scriptName = extractString(keys: ["script_name", "name", "project_name", "deployment_id"])
            let env = extractString(keys: ["environment", "tag", "branch"])
            if let s = scriptName, !s.isEmpty {
                if let e = env, !e.isEmpty {
                    Text(verbatim: "\(s) (\(e))")
                } else {
                    Text(verbatim: s)
                }
            } else {
                AuditLogsView.friendlyResourceBadge(friendlyResourceTypeKey)
            }
        } else if resType.contains("waf") || resType.contains("rule") || resType.contains("firewall") {
            let ruleName = extractString(keys: ["description", "rule_name", "name", "action"])
            if let r = ruleName, !r.isEmpty {
                Text(verbatim: r)
            } else {
                AuditLogsView.friendlyResourceBadge(friendlyResourceTypeKey)
            }
        } else {
            if let name = extractString(keys: ["name", "title", "description"]), !name.isEmpty, !name.isHexHash {
                Text(verbatim: name)
            } else if let zoneName = zone?.name, !zoneName.isEmpty {
                Text(verbatim: zoneName)
            } else if let resId = resource?.id, !resId.isEmpty {
                if resId.isHexHash {
                    HStack(spacing: 4) {
                        AuditLogsView.friendlyResourceBadge(friendlyResourceTypeKey)
                        Text("(ID: \(shortId(resId)))")
                    }
                } else {
                    Text(verbatim: resId)
                }
            } else {
                Text("Audit Event \(shortId(id))")
            }
        }
    }

    @ViewBuilder
    public var secondaryContextView: some View {
        let zoneName = zone?.name ?? metadata?["zone_name"]?.stringValue
        let listName = extractString(keys: ["list_name"])
        let info = action?.info
        let resId = resource?.id

        HStack(spacing: 6) {
            if let z = zoneName, !z.isEmpty {
                Text("Domain: \(z)")
            }
            if let l = listName, !l.isEmpty {
                Text(verbatim: "List: \(l)")
            }
            if let inf = info, !inf.isEmpty {
                Text(verbatim: inf)
            }
            if let r = resId, !r.isEmpty, r.isHexHash {
                Text("Resource: \(shortId(r))")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private func extractString(keys: [String]) -> String? {
        if let newJson = newValueJson {
            for k in keys {
                if let val = newJson[k]?.stringValue, !val.isEmpty {
                    return val
                }
            }
        }
        if let oldJson = oldValueJson {
            for k in keys {
                if let val = oldJson[k]?.stringValue, !val.isEmpty {
                    return val
                }
            }
        }
        if let meta = metadata {
            for k in keys {
                if let val = meta[k]?.stringValue, !val.isEmpty {
                    return val
                }
            }
        }
        if case let .dictionary(dict) = newValue {
            for k in keys {
                if let val = dict[k]?.stringValue, !val.isEmpty {
                    return val
                }
            }
        }
        if case let .dictionary(dict) = oldValue {
            for k in keys {
                if let val = dict[k]?.stringValue, !val.isEmpty {
                    return val
                }
            }
        }
        return nil
    }

    private func translateSettingKey(_ key: String?) -> String? {
        guard let key = key?.lowercased() else { return nil }
        switch key {
        case "dev_mode", "development_mode": return String(localized: "Development Mode")
        case "always_online": return String(localized: "Always Online")
        case "ssl", "ssl_mode": return String(localized: "SSL Encryption Mode")
        case "security_level": return String(localized: "Security Level")
        case "challenge_ttl": return String(localized: "Challenge TTL")
        case "browser_cache_ttl": return String(localized: "Browser Cache TTL")
        case "cache_level": return String(localized: "Cache Level")
        case "minify": return String(localized: "Auto Minify")
        case "brotli": return String(localized: "Brotli Compression")
        case "http2": return "HTTP/2"
        case "http3": return "HTTP/3 (QUIC)"
        case "0rtt": return "0-RTT Connection"
        case "tls_1_3": return "TLS 1.3"
        case "min_tls_version": return String(localized: "Minimum TLS Version")
        case "websockets": return "WebSockets"
        case "automatic_https_rewrites": return String(localized: "Automatic HTTPS Rewrites")
        case "ip_geolocation": return String(localized: "IP Geolocation")
        case "email_obfuscation": return String(localized: "Email Obfuscation")
        case "server_side_exclude": return String(localized: "Server-Side Excludes")
        case "hotlink_protection": return String(localized: "Hotlink Protection")
        case "rocket_loader": return "Rocket Loader"
        case "polish": return String(localized: "Polish Image Optimization")
        case "mirage": return String(localized: "Mirage Mobile Optimization")
        case "ipv6": return String(localized: "IPv6 Compatibility")
        case "pseudo_ipv4": return "Pseudo IPv4"
        case "waf": return String(localized: "WAF Firewall")
        case "early_hints": return String(localized: "Early Hints")
        case "h2_prioritization": return String(localized: "HTTP/2 Prioritization")
        case "origin_error_page_pass_thru": return String(localized: "Origin Error Page Pass-thru")
        case "proxy_read_timeout": return String(localized: "Proxy Read Timeout")
        default: return key
        }
    }

    private func translateSettingValue(_ val: String?) -> String? {
        guard let val = val?.lowercased() else { return nil }
        switch val {
        case "on", "true", "1": return String(localized: "On")
        case "off", "false", "0": return String(localized: "Off")
        case "strict": return String(localized: "Full (Strict)")
        case "full": return String(localized: "Full")
        case "flexible": return String(localized: "Flexible")
        case "essentially_off": return String(localized: "Essentially Off")
        case "low": return String(localized: "Low")
        case "medium": return String(localized: "Medium")
        case "high": return String(localized: "High")
        case "under_attack": return String(localized: "Under Attack")
        default: return val
        }
    }

    private func shortId(_ id: String) -> String {
        if id.count > 12 {
            return String(id.prefix(8)) + "..."
        }
        return id
    }
}

private extension String {
    var isHexHash: Bool {
        guard count >= 16 else { return false }
        let hexChars = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return unicodeScalars.allSatisfy { hexChars.contains($0) }
    }
}
