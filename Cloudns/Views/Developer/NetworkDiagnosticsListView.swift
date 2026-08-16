import SwiftUI

struct NetworkDiagnosticsListView: View {
    @State private var searchText = ""
    
    private struct DiagnosticToolItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let iconColor: Color
        let badge: String
        let destination: AnyView
    }
    
    private var allTools: [DiagnosticToolItem] {
        [
            DiagnosticToolItem(
                title: "Cloudflare Trace",
                subtitle: "Edge PoP data center & client trace (/cdn-cgi/trace)",
                icon: "antenna.radiowaves.left.and.right.circle.fill",
                iconColor: .orange,
                badge: "Trace",
                destination: AnyView(CFTraceToolView())
            ),
            DiagnosticToolItem(
                title: "DNS Dig (1.1.1.1)",
                subtitle: "Recursive DNS over HTTPS query & response timing",
                icon: "magnifyingglass.circle.fill",
                iconColor: .indigo,
                badge: "DoH",
                destination: AnyView(DNSDigToolView())
            ),
            DiagnosticToolItem(
                title: "HTTP & Cache Inspector",
                subtitle: "Inspect CF-Ray, CF-Cache-Status & edge headers",
                icon: "arrow.up.right.circle.fill",
                iconColor: .blue,
                badge: "HTTP",
                destination: AnyView(HTTPHeaderInspectorView())
            ),
            DiagnosticToolItem(
                title: "SSL Certificate Inspector",
                subtitle: "Deep certificate chain, SANs & expiration analysis",
                icon: "checkmark.seal.fill",
                iconColor: .green,
                badge: "TLS",
                destination: AnyView(CertInspectToolView())
            ),
            DiagnosticToolItem(
                title: "IP & ASN Lookup",
                subtitle: "Geolocation, ISP organization & network ASN diagnosis",
                icon: "location.circle.fill",
                iconColor: .teal,
                badge: "IP",
                destination: AnyView(IPLookupToolView())
            ),
            DiagnosticToolItem(
                title: "WHOIS & RDAP Lookup",
                subtitle: "Domain registrar, creation date & nameserver records",
                icon: "person.text.rectangle.fill",
                iconColor: .purple,
                badge: "RDAP",
                destination: AnyView(WhoisToolView())
            ),
            DiagnosticToolItem(
                title: "Cloudflare IP Ranges",
                subtitle: "Official IPv4/IPv6 CIDRs & Nginx allowlist export",
                icon: "network.badge.shield.half.filled",
                iconColor: .cyan,
                badge: "CIDR",
                destination: AnyView(CFIpRangesToolView())
            )
        ]
    }
    
    private var filteredTools: [DiagnosticToolItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return allTools
        }
        return allTools.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText) ||
            $0.badge.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            if filteredTools.isEmpty {
                Section {
                    EmptyStateView.search(query: searchText) {
                        searchText = ""
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("Network & Security Diagnostics (\(filteredTools.count))"), footer: Text("All diagnostics queries run directly from your device or Cloudflare's 1.1.1.1 edge network.")) {
                    ForEach(filteredTools) { tool in
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
                                    HStack {
                                        Text(tool.title)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                        
                                        Text(tool.badge)
                                            .font(.caption2)
                                            .foregroundStyle(tool.iconColor)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(tool.iconColor.opacity(0.12))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text(tool.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Network Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Diagnostic Tools")
    }
}
