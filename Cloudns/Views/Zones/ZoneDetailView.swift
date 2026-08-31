import SwiftUI

// MARK: - ZoneDetailView

struct ZoneDetailView: View {
    let initialZone: Zone
    @State private var zone: Zone
    @Environment(\.dismiss) private var dismiss

    init(zone: Zone) {
        self.initialZone = zone
        self._zone = State(initialValue: zone)
    }

    var body: some View {
        List {
            // Domain Status & Info Section
            Section(header: Text("Domain Info")) {
                LabeledContent("Status") {
                    HIGBadge(
                        zone.status.lowercased() == "active" ? .active : (zone.status.lowercased() == "pending" ? .warning("Pending") : .custom(color: .secondary, text: zone.status.capitalized)),
                        isCompact: true
                    )
                }
                
                if let planName = zone.plan?.displayName {
                    LabeledContent("Plan") {
                        Text(planName)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let type = zone.type {
                    LabeledContent("Setup Type") {
                        Text(type.uppercased())
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let nsArray = zone.nameServers, !nsArray.isEmpty {
                    ForEach(Array(nsArray.enumerated()), id: \.offset) { index, ns in
                        LabeledContent {
                            Button {
                                UIPasteboard.general.string = ns
                                ToastManager.shared.showCopied("Nameserver Copied")
                            } label: {
                                HStack(spacing: 6) {
                                    Text(ns)
                                        .font(.subheadline.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .buttonStyle(.higPressable)
                            .higTouchTarget()
                        } label: {
                            Text(nsArray.count > 1 ? "Nameserver \(index + 1)" : "Nameserver")
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }

            // Analytics
            Section(header: Text("Analytics")) {
                ZoneNavRowView(
                    title: "Traffic",
                    subtitle: "Requests, bandwidth & threats",
                    icon: "chart.xyaxis.line",
                    color: .indigo,
                    destination: ZoneAnalyticsView(zoneId: zone.id, zoneName: zone.name)
                )
            }

            // DNS
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

            // Security
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
                    icon: "slider.horizontal.3",
                    color: .gray,
                    destination: SecuritySettingsView(zoneId: zone.id)
                )
            }

            // SSL / TLS
            Section(header: Text("SSL/TLS")) {
                ZoneNavRowView(
                    title: "Overview",
                    subtitle: "Encryption mode & HTTPS settings",
                    icon: "lock.shield.fill",
                    color: .orange,
                    destination: SSLSettingsView(zoneId: zone.id)
                )
                ZoneNavRowView(
                    title: "Edge Certificates",
                    subtitle: "Universal, ACM & custom certificates",
                    icon: "checkmark.seal.fill",
                    color: .orange,
                    destination: EdgeCertificatesView(zoneId: zone.id)
                )
            }

            // Performance
            Section(header: Text("Performance")) {
                ZoneNavRowView(
                    title: "Speed",
                    subtitle: "Minification, Brotli, HTTP/2",
                    icon: "speedometer",
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
                    icon: "slider.horizontal.3",
                    color: .teal,
                    destination: RulesHubView(zoneId: zone.id)
                )
            }

            // Network
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
                    badge: .warning("ADD-ON"),
                    destination: LoadBalancerView(zoneId: zone.id)
                )
            }

            // Email
            Section(header: Text("Email")) {
                ZoneNavRowView(
                    title: "Email Routing",
                    subtitle: "Forward addresses to your inbox",
                    icon: "envelope.fill",
                    color: .indigo,
                    destination: EmailRoutingView(zoneId: zone.id, zoneName: zone.name)
                )
            }

            // Content
            Section(header: Text("Content")) {
                ZoneNavRowView(
                    title: "Scrape Shield",
                    subtitle: "Email obfuscation & hotlink protection",
                    icon: "eye.slash.fill",
                    color: .gray,
                    destination: ScrapeShieldView(zoneId: zone.id)
                )
            }

            // Advanced
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
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshZoneDetails()
        }
        .task {
            await refreshZoneDetails()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoneUpdated)) { _ in
            Task { await refreshZoneDetails() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoneDeleted)) { notif in
            if let deletedId = notif.userInfo?["zoneId"] as? String {
                if deletedId == zone.id {
                    dismiss()
                }
            } else {
                dismiss()
            }
        }
        .onAppear {
            RecentZonesManager.shared.recordVisit(zoneId: zone.id)
            WidgetDataStore.shared.syncZoneWithAnalytics(zone: zone)
        }
    }
    
    private func refreshZoneDetails() async {
        do {
            let updated = try await ZoneService.shared.getZoneDetails(zoneId: initialZone.id)
            await MainActor.run {
                withAnimation {
                    self.zone = updated
                }
                RecentZonesManager.shared.recordVisit(zoneId: updated.id)
                WidgetDataStore.shared.syncZoneWithAnalytics(zone: updated)
            }
        } catch {
            // Keep current zone snapshot if offline
        }
    }
}

// MARK: - ZoneNavRowView (Inlined & Cohesive)

struct ZoneNavRowView<Destination: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let color: Color
    let badge: HIGBadgeType?
    let destination: Destination

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        color: Color,
        badge: HIGBadgeType? = nil,
        destination: Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.badge = badge
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        if let badge = badge {
                            HIGBadge(badge, isCompact: true)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
        }
    }
}
