import SwiftUI

// MARK: - NetworkToolsView (Top-Level Tab)

// Apple HIG Compliant Diagnostic & Network Tools Hub with Instant Search

struct NetworkToolsView: View {
    @State private var searchText = ""

    // MARK: - Diagnostic Tool Models

    enum DiagnosticToolType: String, Identifiable, CaseIterable {
        case cfTrace
        case cfStatus
        case dnsDig
        case httpHeader
        case certInspect
        case dnsPropagation
        case edgeLatency
        case ipLookup
        case whois
        case cfIpRanges
        case cidrCalc

        var id: String {
            rawValue
        }

        var title: LocalizedStringKey {
            switch self {
            case .cfTrace: "Cloudflare Trace"
            case .cfStatus: "Cloudflare System Status"
            case .dnsDig: "DNS Dig & Benchmark"
            case .httpHeader: "HTTP & Cache Inspector"
            case .certInspect: "SSL Certificate Inspector"
            case .dnsPropagation: "Global DNS Propagation"
            case .edgeLatency: "Edge Latency & Jitter"
            case .ipLookup: "IP & ASN Lookup"
            case .whois: "WHOIS & RDAP Lookup"
            case .cfIpRanges: "Cloudflare IP Ranges"
            case .cidrCalc: "Subnet & CIDR Calculator"
            }
        }

        var searchKeywords: String {
            switch self {
            case .cfTrace: "trace cdn cgi pop datacenter route ip 路由 节点 跟踪"
            case .cfStatus: "status cloudflare incident outage maintenance pop operational 状态 故障 维护 节点 服务"
            case .dnsDig: "dns dig rfc 1.1.1.1 resolve benchmark dnssec 解析 查询"
            case .httpHeader: "http cache cf ray header timing status inspect 缓存 响应头"
            case .certInspect: "ssl tls cert certificate chain san expiration 证书 检查"
            case .dnsPropagation: "propagation worldwide global dns probe resolve 传播 全球 解析"
            case .edgeLatency: "ping latency jitter speed packet loss timing 延迟 测速 丢包 抖动"
            case .ipLookup: "ip asn anycast isp geo location country 归属地 运营商"
            case .whois: "whois rdap registrar domain expiry nameservers 域名 信息 到期"
            case .cfIpRanges: "ip ranges cidr ipv4 ipv6 official firewall 官方 地址段 白名单"
            case .cidrCalc: "cidr subnet mask network ip calculator hosts 子网 掩码 计算器"
            }
        }

        var subtitle: LocalizedStringKey {
            switch self {
            case .cfTrace: "Edge PoP data center & client route trace (/cdn-cgi/trace)"
            case .cfStatus: "Official services, incident reports & global PoP health"
            case .dnsDig: "1.1.1.1 query, DNSSEC validation & 5-resolver benchmark"
            case .httpHeader: "CF-Ray, CF-Cache-Status, HTTP/3 & edge timing breakdown"
            case .certInspect: "Certificate chain hierarchy, SANs & expiration countdown"
            case .dnsPropagation: "Probe worldwide resolution across 8 regional edge nodes"
            case .edgeLatency: "Multi-round response timing, packet loss & jitter test"
            case .ipLookup: "Cloudflare Anycast detection, ISP organization & ASN"
            case .whois: "Domain registrar, lifecycle timeline & nameserver records"
            case .cfIpRanges: "Official IPv4/IPv6 CIDRs, IP matcher & firewall exporter"
            case .cidrCalc: "IPv4/IPv6 network mask, broadcast & host range calculator"
            }
        }

        var icon: String {
            switch self {
            case .cfTrace: "antenna.radiowaves.left.and.right"
            case .cfStatus: "antenna.radiowaves.left.and.right"
            case .dnsDig: "magnifyingglass"
            case .httpHeader: "arrow.up.right"
            case .certInspect: "checkmark.seal.fill"
            case .dnsPropagation: "globe.americas.fill"
            case .edgeLatency: "speedometer"
            case .ipLookup: "location.fill"
            case .whois: "person.text.rectangle.fill"
            case .cfIpRanges: "network.badge.shield.half.filled"
            case .cidrCalc: "number"
            }
        }

        @MainActor
        var iconColor: Color {
            switch self {
            case .cfTrace: .orange
            case .cfStatus: ThemeManager.shared.accentColor
            case .dnsDig: .indigo
            case .httpHeader: .blue
            case .certInspect: .green
            case .dnsPropagation: .indigo
            case .edgeLatency: .purple
            case .ipLookup: .teal
            case .whois: .purple
            case .cfIpRanges: .cyan
            case .cidrCalc: .blue
            }
        }

        @ViewBuilder
        @MainActor
        var destinationView: some View {
            switch self {
            case .cfTrace: CFTraceToolView()
            case .cfStatus: CloudflareStatusView()
            case .dnsDig: DNSDigToolView()
            case .httpHeader: HTTPHeaderInspectorView()
            case .certInspect: CertInspectToolView()
            case .dnsPropagation: DNSPropagationView()
            case .edgeLatency: EdgeLatencyTestView()
            case .ipLookup: IPLookupToolView()
            case .whois: WhoisToolView()
            case .cfIpRanges: CFIpRangesToolView()
            case .cidrCalc: CIDRCalculatorView()
            }
        }
    }

    private let edgeTools: [DiagnosticToolType] = [.cfTrace, .dnsDig, .httpHeader, .certInspect]
    private let globalProbingTools: [DiagnosticToolType] = [.cfStatus, .dnsPropagation, .edgeLatency]
    private let ipRoutingTools: [DiagnosticToolType] = [.ipLookup, .whois, .cfIpRanges, .cidrCalc]

    private var filteredTools: [DiagnosticToolType] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return DiagnosticToolType.allCases
        }
        let q = searchText.lowercased()
        return DiagnosticToolType.allCases.filter { tool in
            tool.id.lowercased().contains(q) ||
                tool.searchKeywords.lowercased().contains(q)
        }
    }

    let embeddedInNavigation: Bool

    init(embeddedInNavigation: Bool = false) {
        self.embeddedInNavigation = embeddedInNavigation
    }

    var body: some View {
        if embeddedInNavigation {
            toolsContent
                .navigationBarTitleDisplayMode(.inline)
        } else {
            NavigationStack {
                toolsContent
                    .navigationBarTitleDisplayMode(.large)
            }
        }
    }

    private var toolsContent: some View {
        List {
            if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                Section("Edge Diagnostics") {
                    ForEach(edgeTools) { tool in
                        toolRow(tool)
                    }
                }

                Section("Global Connectivity & Probing") {
                    ForEach(globalProbingTools) { tool in
                        toolRow(tool)
                    }
                }

                Section {
                    ForEach(ipRoutingTools) { tool in
                        toolRow(tool)
                    }
                } header: {
                    Text("IP & Routing Utilities")
                } footer: {
                    Text("All diagnostics queries run directly from your device or Cloudflare's global edge network.")
                }
            } else {
                Section("Matching Tools (\(filteredTools.count))") {
                    ForEach(filteredTools) { tool in
                        toolRow(tool)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Diagnostics & Tools"
        )
        .navigationTitle("Tools")
        .listState(
            isEmpty: !searchText.isEmpty && filteredTools.isEmpty,
            empty: EmptyStateConfig(
                title: "No Results",
                systemImage: "magnifyingglass",
                description: "No diagnostics tools matching '\(searchText)'."
            )
        )
    }

    private func toolRow(_ tool: DiagnosticToolType) -> some View {
        NavigationLink {
            tool.destinationView
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ListRowIcon(icon: tool.icon, color: tool.iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    Text(tool.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
        }
    }
}
