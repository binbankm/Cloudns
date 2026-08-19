import SwiftUI

struct NetworkDiagnosticsListView: View {
    private struct DiagnosticToolItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let iconColor: Color
        let destination: AnyView
    }
    
    private var edgeTools: [DiagnosticToolItem] {
        [
            DiagnosticToolItem(
                title: "Cloudflare Trace",
                subtitle: "Edge PoP data center & client route trace (/cdn-cgi/trace)",
                icon: "antenna.radiowaves.left.and.right.circle.fill",
                iconColor: .orange,
                destination: AnyView(CFTraceToolView())
            ),
            DiagnosticToolItem(
                title: "DNS Dig & Benchmark",
                subtitle: "1.1.1.1 query, DNSSEC validation & 5-resolver benchmark",
                icon: "magnifyingglass.circle.fill",
                iconColor: .indigo,
                destination: AnyView(DNSDigToolView())
            ),
            DiagnosticToolItem(
                title: "HTTP & Cache Inspector",
                subtitle: "CF-Ray, CF-Cache-Status, HTTP/3 & edge timing breakdown",
                icon: "arrow.up.right.circle.fill",
                iconColor: .blue,
                destination: AnyView(HTTPHeaderInspectorView())
            ),
            DiagnosticToolItem(
                title: "SSL Certificate Inspector",
                subtitle: "Certificate chain hierarchy, SANs & expiration countdown",
                icon: "checkmark.seal.fill",
                iconColor: .green,
                destination: AnyView(CertInspectToolView())
            )
        ]
    }
    
    private var globalProbingTools: [DiagnosticToolItem] {
        [
            DiagnosticToolItem(
                title: "Global DNS Propagation",
                subtitle: "Probe worldwide resolution across 8 regional edge nodes",
                icon: "globe.americas.fill",
                iconColor: .indigo,
                destination: AnyView(DNSPropagationView())
            ),
            DiagnosticToolItem(
                title: "Edge Latency & Jitter",
                subtitle: "Multi-round response timing, packet loss & jitter test",
                icon: "speedometer",
                iconColor: .purple,
                destination: AnyView(EdgeLatencyTestView())
            )
        ]
    }
    
    private var ipRoutingTools: [DiagnosticToolItem] {
        [
            DiagnosticToolItem(
                title: "IP & ASN Lookup",
                subtitle: "Cloudflare Anycast detection, ISP organization & ASN",
                icon: "location.circle.fill",
                iconColor: .teal,
                destination: AnyView(IPLookupToolView())
            ),
            DiagnosticToolItem(
                title: "WHOIS & RDAP Lookup",
                subtitle: "Domain registrar, lifecycle timeline & nameserver records",
                icon: "person.text.rectangle.fill",
                iconColor: .purple,
                destination: AnyView(WhoisToolView())
            ),
            DiagnosticToolItem(
                title: "Cloudflare IP Ranges",
                subtitle: "Official IPv4/IPv6 CIDRs, IP matcher & firewall exporter",
                icon: "network.badge.shield.half.filled",
                iconColor: .cyan,
                destination: AnyView(CFIpRangesToolView())
            ),
            DiagnosticToolItem(
                title: "Subnet & CIDR Calculator",
                subtitle: "IPv4/IPv6 network mask, broadcast & host range calculator",
                icon: "number.square.fill",
                iconColor: .blue,
                destination: AnyView(CIDRCalculatorView())
            )
        ]
    }
    
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
    private func toolRow(_ tool: DiagnosticToolItem) -> some View {
        NavigationLink {
            tool.destination
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: tool.icon)
                    .font(.body)
                    .foregroundStyle(tool.iconColor)
                    .frame(width: 32, height: 32)
                    .background(tool.iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(tool.title))
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text(LocalizedStringKey(tool.subtitle))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 3)
        }
    }
}
