import SwiftUI

// MARK: - NetworkToolsView (Top-Level Tab)

struct NetworkToolsView: View {
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    
    // MARK: - Diagnostic Tool Models
    
    enum DiagnosticToolType: String, Identifiable, CaseIterable {
        case cfTrace
        case dnsDig
        case httpHeader
        case certInspect
        case dnsPropagation
        case edgeLatency
        case ipLookup
        case whois
        case cfIpRanges
        case cidrCalc
        
        var id: String { rawValue }
        
        var title: LocalizedStringKey {
            switch self {
            case .cfTrace: return "Cloudflare Trace"
            case .dnsDig: return "DNS Dig & Benchmark"
            case .httpHeader: return "HTTP & Cache Inspector"
            case .certInspect: return "SSL Certificate Inspector"
            case .dnsPropagation: return "Global DNS Propagation"
            case .edgeLatency: return "Edge Latency & Jitter"
            case .ipLookup: return "IP & ASN Lookup"
            case .whois: return "WHOIS & RDAP Lookup"
            case .cfIpRanges: return "Cloudflare IP Ranges"
            case .cidrCalc: return "Subnet & CIDR Calculator"
            }
        }
        
        var searchKeywords: String {
            switch self {
            case .cfTrace: return "trace cdn cgi pop datacenter route ip"
            case .dnsDig: return "dns dig rfc 1.1.1.1 resolve benchmark dnssec"
            case .httpHeader: return "http cache cf ray header timing status inspect"
            case .certInspect: return "ssl tls cert certificate chain san expiration"
            case .dnsPropagation: return "propagation worldwide global dns probe resolve"
            case .edgeLatency: return "ping latency jitter speed packet loss timing"
            case .ipLookup: return "ip asn anycast isp geo location country"
            case .whois: return "whois rdap registrar domain expiry nameservers"
            case .cfIpRanges: return "ip ranges cidr ipv4 ipv6 official firewall"
            case .cidrCalc: return "cidr subnet mask network ip calculator hosts"
            }
        }
        
        var subtitle: LocalizedStringKey {
            switch self {
            case .cfTrace: return "Edge PoP data center & client route trace (/cdn-cgi/trace)"
            case .dnsDig: return "1.1.1.1 query, DNSSEC validation & 5-resolver benchmark"
            case .httpHeader: return "CF-Ray, CF-Cache-Status, HTTP/3 & edge timing breakdown"
            case .certInspect: return "Certificate chain hierarchy, SANs & expiration countdown"
            case .dnsPropagation: return "Probe worldwide resolution across 8 regional edge nodes"
            case .edgeLatency: return "Multi-round response timing, packet loss & jitter test"
            case .ipLookup: return "Cloudflare Anycast detection, ISP organization & ASN"
            case .whois: return "Domain registrar, lifecycle timeline & nameserver records"
            case .cfIpRanges: return "Official IPv4/IPv6 CIDRs, IP matcher & firewall exporter"
            case .cidrCalc: return "IPv4/IPv6 network mask, broadcast & host range calculator"
            }
        }
        
        var icon: String {
            switch self {
            case .cfTrace: return "antenna.radiowaves.left.and.right.circle.fill"
            case .dnsDig: return "magnifyingglass.circle.fill"
            case .httpHeader: return "arrow.up.right.circle.fill"
            case .certInspect: return "checkmark.seal.fill"
            case .dnsPropagation: return "globe.americas.fill"
            case .edgeLatency: return "speedometer"
            case .ipLookup: return "location.circle.fill"
            case .whois: return "person.text.rectangle.fill"
            case .cfIpRanges: return "network.badge.shield.half.filled"
            case .cidrCalc: return "number.square.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .cfTrace: return .orange
            case .dnsDig: return .indigo
            case .httpHeader: return .blue
            case .certInspect: return .green
            case .dnsPropagation: return .indigo
            case .edgeLatency: return .purple
            case .ipLookup: return .teal
            case .whois: return .purple
            case .cfIpRanges: return .cyan
            case .cidrCalc: return .blue
            }
        }
        
        @ViewBuilder
        @MainActor
        var destinationView: some View {
            switch self {
            case .cfTrace: CFTraceToolView()
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
    private let globalProbingTools: [DiagnosticToolType] = [.dnsPropagation, .edgeLatency]
    private let ipRoutingTools: [DiagnosticToolType] = [.ipLookup, .whois, .cfIpRanges, .cidrCalc]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Edge Diagnostics")) {
                    ForEach(edgeTools) { tool in
                        toolRow(tool)
                    }
                }
                
                Section(header: Text("Global Connectivity & Probing")) {
                    ForEach(globalProbingTools) { tool in
                        toolRow(tool)
                    }
                }
                
                Section(
                    header: Text("IP & Routing Utilities"),
                    footer: Text("All diagnostics queries run directly from your device or Cloudflare's global edge network.")
                ) {
                    ForEach(ipRoutingTools) { tool in
                        toolRow(tool)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.large)
            .id(appLanguage)
        }
    }
    
    @ViewBuilder
    private func toolRow(_ tool: DiagnosticToolType) -> some View {
        NavigationLink {
            tool.destinationView
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ListRowIcon(icon: tool.icon, color: tool.iconColor, size: 28, cornerRadius: 6)
                
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
        }
    }
}
