import SwiftUI

// MARK: - DNSPreset Model

struct DNSPresetItem: Identifiable {
    let id = UUID()
    let type: String
    let nameSuffix: String
    let content: String
    let priority: Int?
    let proxied: Bool
    let ttl: Int
    let comment: String?
}

struct DNSPresetGroup: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let category: String
    let items: [DNSPresetItem]
}

// MARK: - Preset Library Definitions

enum DNSPresetLibrary {
    static func getPresets(zoneName: String) -> [DNSPresetGroup] {
        [
            DNSPresetGroup(
                id: "tencent_exmail",
                title: "Tencent Exmail",
                subtitle: "Tencent enterprise email MX & SPF records",
                icon: "envelope.fill",
                iconColor: .blue,
                category: "Enterprise Email",
                items: [
                    DNSPresetItem(type: "MX", nameSuffix: "@", content: "mxbiz1.qq.com", priority: 5, proxied: false, ttl: 1, comment: "Tencent Exmail Primary"),
                    DNSPresetItem(type: "MX", nameSuffix: "@", content: "mxbiz2.qq.com", priority: 10, proxied: false, ttl: 1, comment: "Tencent Exmail Secondary"),
                    DNSPresetItem(type: "TXT", nameSuffix: "@", content: "v=spf1 include:spf.mail.qq.com ~all", priority: nil, proxied: false, ttl: 1, comment: "Tencent Exmail SPF")
                ]
            ),
            DNSPresetGroup(
                id: "feishu_mail",
                title: "Feishu / Lark Mail",
                subtitle: "Feishu enterprise email MX & SPF records",
                icon: "paperplane.fill",
                iconColor: .teal,
                category: "Enterprise Email",
                items: [
                    DNSPresetItem(type: "MX", nameSuffix: "@", content: "mx.feishu.cn", priority: 5, proxied: false, ttl: 1, comment: "Feishu Mail Primary"),
                    DNSPresetItem(type: "TXT", nameSuffix: "@", content: "v=spf1 include:spf.feishu.cn ~all", priority: nil, proxied: false, ttl: 1, comment: "Feishu Mail SPF")
                ]
            ),
            DNSPresetGroup(
                id: "netease_mail",
                title: "NetEase Qiye Mail",
                subtitle: "163 NetEase enterprise email MX & SPF",
                icon: "envelope.badge.fill",
                iconColor: .red,
                category: "Enterprise Email",
                items: [
                    DNSPresetItem(type: "MX", nameSuffix: "@", content: "mxhz01.qiye.163.com", priority: 5, proxied: false, ttl: 1, comment: "NetEase Mail Primary"),
                    DNSPresetItem(type: "MX", nameSuffix: "@", content: "mxhz02.qiye.163.com", priority: 10, proxied: false, ttl: 1, comment: "NetEase Mail Secondary"),
                    DNSPresetItem(type: "TXT", nameSuffix: "@", content: "v=spf1 include:spf.163.com ~all", priority: nil, proxied: false, ttl: 1, comment: "NetEase Mail SPF")
                ]
            ),
            DNSPresetGroup(
                id: "google_workspace",
                title: "Google Workspace",
                subtitle: "Gmail custom domain routing & SPF",
                icon: "g.circle.fill",
                iconColor: .red,
                category: "Enterprise Email",
                items: [
                    DNSPresetItem(type: "MX", nameSuffix: "@", content: "smtp.google.com", priority: 1, proxied: false, ttl: 1, comment: "Google Workspace MX"),
                    DNSPresetItem(type: "TXT", nameSuffix: "@", content: "v=spf1 include:_spf.google.com ~all", priority: nil, proxied: false, ttl: 1, comment: "Google Workspace SPF")
                ]
            ),
            DNSPresetGroup(
                id: "microsoft_365",
                title: "Microsoft 365",
                subtitle: "Outlook custom domain SPF & autodiscover",
                icon: "building.2.fill",
                iconColor: .blue,
                category: "Enterprise Email",
                items: [
                    DNSPresetItem(type: "TXT", nameSuffix: "@", content: "v=spf1 include:spf.protection.outlook.com -all", priority: nil, proxied: false, ttl: 1, comment: "Microsoft 365 SPF"),
                    DNSPresetItem(type: "CNAME", nameSuffix: "autodiscover", content: "autodiscover.outlook.com", priority: nil, proxied: false, ttl: 1, comment: "Outlook Autodiscover")
                ]
            ),
            DNSPresetGroup(
                id: "icloud_mail",
                title: "iCloud+ Custom Domain",
                subtitle: "Apple iCloud+ email MX & SPF",
                icon: "apple.logo",
                iconColor: .indigo,
                category: "Enterprise Email",
                items: [
                    DNSPresetItem(type: "MX", nameSuffix: "@", content: "mx01.mail.icloud.com", priority: 10, proxied: false, ttl: 1, comment: "iCloud Mail Primary"),
                    DNSPresetItem(type: "MX", nameSuffix: "@", content: "mx02.mail.icloud.com", priority: 10, proxied: false, ttl: 1, comment: "iCloud Mail Secondary"),
                    DNSPresetItem(type: "TXT", nameSuffix: "@", content: "v=spf1 include:icloud.com ~all", priority: nil, proxied: false, ttl: 1, comment: "iCloud Mail SPF")
                ]
            ),
            DNSPresetGroup(
                id: "github_pages",
                title: "GitHub Pages",
                subtitle: "4 Apex IPv4 addresses for fast GitHub Pages CDN",
                icon: "globe",
                iconColor: .purple,
                category: "Web Hosting",
                items: [
                    DNSPresetItem(type: "A", nameSuffix: "@", content: "185.199.108.153", priority: nil, proxied: false, ttl: 1, comment: "GitHub Pages"),
                    DNSPresetItem(type: "A", nameSuffix: "@", content: "185.199.109.153", priority: nil, proxied: false, ttl: 1, comment: "GitHub Pages"),
                    DNSPresetItem(type: "A", nameSuffix: "@", content: "185.199.110.153", priority: nil, proxied: false, ttl: 1, comment: "GitHub Pages"),
                    DNSPresetItem(type: "A", nameSuffix: "@", content: "185.199.111.153", priority: nil, proxied: false, ttl: 1, comment: "GitHub Pages")
                ]
            ),
            DNSPresetGroup(
                id: "vercel",
                title: "Vercel",
                subtitle: "Apex A record pointing to 76.76.21.21",
                icon: "triangle.fill",
                iconColor: .primary,
                category: "Web Hosting",
                items: [
                    DNSPresetItem(type: "A", nameSuffix: "@", content: "76.76.21.21", priority: nil, proxied: false, ttl: 1, comment: "Vercel Apex")
                ]
            ),
            DNSPresetGroup(
                id: "dmarc_quarantine",
                title: "DMARC Protection",
                subtitle: "Prevent email spoofing with quarantine policy",
                icon: "shield.lefthalf.filled",
                iconColor: .green,
                category: "Security & Anti-Spoof",
                items: [
                    DNSPresetItem(type: "TXT", nameSuffix: "_dmarc", content: "v=DMARC1; p=quarantine; pct=100", priority: nil, proxied: false, ttl: 1, comment: "DMARC Policy")
                ]
            )
        ]
    }
}

// MARK: - DNSPresetsSheetView
// Apple HIG Compliant 1-Click DNS Presets (iOS 16.0+)

struct DNSPresetsSheetView: View {
    let zoneName: String
    let zoneId: String
    @ObservedObject var viewModel: DNSRecordsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedGroup: DNSPresetGroup?
    @State private var isApplying = false
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var accentColor: Color {
        themeManager.currentColor.color
    }
    
    private var presets: [DNSPresetGroup] {
        DNSPresetLibrary.getPresets(zoneName: zoneName)
    }
    
    private var categories: [String] {
        Array(Set(presets.map { $0.category })).sorted()
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.title2)
                            .foregroundStyle(accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("1-Click DNS Presets")
                                .font(.headline)
                            Text("Quickly configure enterprise email, web hosting, and security policies without typing record values.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                ForEach(categories, id: \.self) { category in
                    Section(header: Text(category)) {
                        ForEach(presets.filter { $0.category == category }) { preset in
                            Button {
                                HapticManager.selection()
                                selectedGroup = preset
                            } label: {
                                HStack(spacing: 12) {
                                    ListRowIcon(icon: preset.icon, color: preset.iconColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.title)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(preset.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(preset.items.count) records")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(uiColor: .tertiarySystemFill))
                                        .clipShape(Capsule())
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("DNS Presets")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor)
                }
            }
            .sheet(item: $selectedGroup) { group in
                presetDetailSheet(for: group)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func presetDetailSheet(for group: DNSPresetGroup) -> some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: group.icon, color: group.iconColor)
                            Text(group.title)
                                .font(.title3.weight(.bold))
                        }
                        Text(group.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Records to Create (\(group.items.count))")) {
                    ForEach(group.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(verbatim: item.type)
                                    .font(.caption.monospacedDigit().weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                
                                Text(item.nameSuffix == "@" ? zoneName : "\(item.nameSuffix).\(zoneName)")
                                    .font(.subheadline.monospaced().weight(.medium))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if let prio = item.priority {
                                    Text("Pri \(prio)")
                                        .font(.caption2.monospacedDigit().weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Text(verbatim: item.content)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await applyPreset(group: group)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isApplying {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 6)
                            }
                            Text(isApplying ? "Adding Records…" : "Apply Preset to \(zoneName)")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
                    .disabled(isApplying)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(group.title)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedGroup = nil
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor)
                }
            }
        }
    }
    
    private func applyPreset(group: DNSPresetGroup) async {
        isApplying = true
        HapticManager.impact(.medium)
        
        var successCount = 0
        for item in group.items {
            let recordName = item.nameSuffix == "@" ? zoneName : "\(item.nameSuffix).\(zoneName)"
            let payload = DNSRecordPayload(
                type: item.type,
                name: recordName,
                content: item.content,
                ttl: item.ttl,
                proxied: item.proxied,
                priority: item.priority,
                comment: item.comment,
                data: nil
            )
            
            do {
                try await viewModel.addRecord(payload: payload)
                successCount += 1
            } catch {
                // Continue with remaining records
            }
        }
        
        isApplying = false
        selectedGroup = nil
        
        if successCount > 0 {
            ToastManager.shared.showSuccess("DNS Presets Applied (\(successCount))", icon: "wand.and.stars")
            dismiss()
        } else {
            ToastManager.shared.showError("Failed to Apply Presets")
        }
    }
}
