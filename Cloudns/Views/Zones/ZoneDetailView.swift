import SwiftUI

// MARK: - ZoneDetailView

struct ZoneDetailView: View {
    let zone: Zone

    var body: some View {
        List {
            // ── Header Card ──────────────────────────────────────────────
            Section {
                ZoneHeaderCardView(zone: zone)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // ── Analytics ────────────────────────────────────────────────
            Section(header: Text("Analytics")) {
                ZoneNavRowView(
                    title: "Traffic",
                    subtitle: "Requests, bandwidth & threats",
                    icon: "chart.xyaxis.line",
                    color: .indigo,
                    destination: AnalyticsView(zoneId: zone.id, zoneName: zone.name)
                )
            }

            // ── DNS ──────────────────────────────────────────────────────
            Section(header: Text("DNS")) {
                ZoneNavRowView(
                    title: "Records",
                    subtitle: "A, CNAME, MX, TXT and more",
                    icon: "server.rack",
                    color: .blue,
                    destination: DNSRecordsView(zoneId: zone.id, zoneName: zone.name)
                )
                ZoneNavRowView(
                    title: "DNSSEC",
                    subtitle: "Sign DNS records to prevent spoofing",
                    icon: "lock.shield.fill",
                    color: .green,
                    destination: DNSSECView(zoneId: zone.id, zoneName: zone.name)
                )
            }

            // ── Security ─────────────────────────────────────────────────
            Section(header: Text("Security")) {
                ZoneNavRowView(
                    title: "Security Events",
                    subtitle: "Firewall activity & triggered rules",
                    icon: "exclamationmark.shield.fill",
                    color: .purple,
                    destination: SecurityEventsView(zoneId: zone.id)
                )
                ZoneNavRowView(
                    title: "WAF",
                    subtitle: "Custom rules, managed rules",
                    icon: "shield.lefthalf.filled",
                    color: .red,
                    destination: WAFCustomRulesView(zoneId: zone.id)
                )
                ZoneNavRowView(
                    title: "Rate Limiting",
                    subtitle: "Throttle excessive request rates",
                    icon: "speedometer",
                    color: .orange,
                    destination: RateLimitingRulesView(zoneId: zone.id)
                )
                ZoneNavRowView(
                    title: "IP Access Rules",
                    subtitle: "Allow or block by IP, ASN, country",
                    icon: "network.badge.shield.half.filled",
                    color: .blue,
                    destination: IPAccessRulesView(zoneId: zone.id)
                )
                ZoneNavRowView(
                    title: "Settings",
                    subtitle: "Security level, Bot Fight Mode",
                    icon: "gear.badge.checkmark",
                    color: .gray,
                    destination: SecuritySettingsView(zoneId: zone.id)
                )
            }

            // ── SSL / TLS ────────────────────────────────────────────────
            Section(header: Text("SSL/TLS")) {
                ZoneNavRowView(
                    title: "Overview",
                    subtitle: "Encryption mode & HTTPS settings",
                    icon: "lock.fill",
                    color: .orange,
                    destination: SSLSettingsView(zoneId: zone.id)
                )
                ZoneNavRowView(
                    title: "Edge Certificates",
                    subtitle: "Universal, ACM & custom certificates",
                    icon: "doc.badge.gearshape.fill",
                    color: .orange,
                    destination: EdgeCertificatesView(zoneId: zone.id)
                )
            }

            // ── Performance ──────────────────────────────────────────────
            Section(header: Text("Performance")) {
                ZoneNavRowView(
                    title: "Speed",
                    subtitle: "Minification, Brotli, HTTP/2",
                    icon: "bolt.fill",
                    color: .yellow,
                    destination: SpeedSettingsView(zoneId: zone.id)
                )
                ZoneNavRowView(
                    title: "Caching",
                    subtitle: "Cache level, browser TTL, purge cache",
                    icon: "memorychip",
                    color: .cyan,
                    destination: CachingView(zoneId: zone.id)
                )
                ZoneNavRowView(
                    title: "Rules",
                    subtitle: "Transform, Cache, Redirect, Snippets",
                    icon: "arrow.triangle.2.circlepath",
                    color: .teal,
                    destination: RulesHubView(zoneId: zone.id)
                )
            }

            // ── Network ──────────────────────────────────────────────────
            Section(header: Text("Network")) {
                ZoneNavRowView(
                    title: "Network",
                    subtitle: "WebSockets, QUIC, gRPC",
                    icon: "network",
                    color: .purple,
                    destination: NetworkCenterView(zoneId: zone.id, zoneName: zone.name)
                )
                ZoneNavRowView(
                    title: "Load Balancing",
                    subtitle: "Distribute traffic across origins",
                    icon: "arrow.triangle.branch",
                    color: .blue,
                    badge: .custom(color: .purple, text: "ADD-ON"),
                    destination: LoadBalancerView(zoneId: zone.id)
                )
            }

            // ── Email ────────────────────────────────────────────────────
            Section(header: Text("Email")) {
                ZoneNavRowView(
                    title: "Email Routing",
                    subtitle: "Forward addresses to your inbox",
                    icon: "envelope.fill",
                    color: .indigo,
                    destination: EmailRoutingView(zoneId: zone.id, zoneName: zone.name)
                )
            }

            // ── Content ──────────────────────────────────────────────────
            Section(header: Text("Content")) {
                ZoneNavRowView(
                    title: "Scrape Shield",
                    subtitle: "Email obfuscation & hotlink protection",
                    icon: "eye.slash.fill",
                    color: .gray,
                    destination: ScrapeShieldView(zoneId: zone.id)
                )
            }

            // ── Quick Controls ───────────────────────────────────────────
            QuickControlsSection(zoneId: zone.id, initialPaused: zone.paused)

            // ── Advanced ─────────────────────────────────────────────────
            Section(header: Text("Advanced")) {
                ZoneNavRowView(
                    title: "Advanced",
                    subtitle: "Pause Cloudflare, remove site",
                    icon: "gearshape.2.fill",
                    color: .red,
                    destination: AdvancedZoneSettingsView(zoneId: zone.id, zoneName: zone.name, initialPaused: zone.paused)
                )
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            RecentZonesManager.shared.recordVisit(zoneId: zone.id)
            let current = WidgetDataStore.shared.loadZoneSnapshot()
            let snap = ZoneWidgetSnapshot(
                id: zone.id,
                name: zone.name,
                status: zone.status,
                plan: zone.plan?.name ?? "Free Plan",
                requests24h: current.id == zone.id ? current.requests24h : 0,
                cachedRatio: current.id == zone.id ? current.cachedRatio : 0.85,
                threats24h: current.id == zone.id ? current.threats24h : 0,
                isProxied: !zone.paused,
                isSSLEnabled: true,
                lastUpdated: Date()
            )
            WidgetDataStore.shared.saveZoneSnapshot(snap)
        }
    }
}
