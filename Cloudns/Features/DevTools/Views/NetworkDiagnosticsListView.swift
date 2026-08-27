import SwiftUI

struct NetworkDiagnosticsListView: View {
    private enum DiagnosticToolType: String, Identifiable, CaseIterable {
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
        
        var title: String {
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
        
        var subtitle: String {
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
    
    // MARK: - Properties
    private let edgeTools: [DiagnosticToolType] = [.cfTrace, .dnsDig, .httpHeader, .certInspect]
    private let globalProbingTools: [DiagnosticToolType] = [.dnsPropagation, .edgeLatency]
    private let ipRoutingTools: [DiagnosticToolType] = [.ipLookup, .whois, .cfIpRanges, .cidrCalc]
    
    // MARK: - Body
    var body: some View {
        List {
            // MARK: - Edge Diagnostics
            Section(header: Text("Network & Edge Diagnostics (\(edgeTools.count))")) {
                ForEach(edgeTools) { tool in
                    toolRow(tool)
                }
            }
            
            // MARK: - Global Probing & Performance
            Section(header: Text("Global Probing & Performance (\(globalProbingTools.count))")) {
                ForEach(globalProbingTools) { tool in
                    toolRow(tool)
                }
            }
            
            // MARK: - IP, Routing & Utilities
            Section(header: Text("IP, Routing & Utilities (\(ipRoutingTools.count))"), footer: Text("All diagnostics queries run directly from your device or Cloudflare's 1.1.1.1 edge network.")) {
                ForEach(ipRoutingTools) { tool in
                    toolRow(tool)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Network Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    // MARK: - Private Views
    private func toolRow(_ tool: DiagnosticToolType) -> some View {
        NavigationLink {
            tool.destinationView
        } label: {
            HStack(alignment: .center, spacing: CloudnsSpacing.mdMedium) {
                Image(systemName: tool.icon)
                    .font(.body)
                    .foregroundStyle(tool.iconColor)
                    .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                    .background(tool.iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                
                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    Text(LocalizedStringKey(tool.title))
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text(LocalizedStringKey(tool.subtitle))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, CloudnsSpacing.xs)
        }
    }
}
