import SwiftUI

// MARK: - ZoneDetailView

struct ZoneDetailView: View {
    let zone: Zone

    var body: some View {
        List {
            // ── Header Card ──────────────────────────────────────────────
            Section {
                ZoneHeaderCard(zone: zone)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // ── Analytics ────────────────────────────────────────────────
            Section(header: Text("Analytics")) {
                ZoneNavRow(
                    title: "Traffic",
                    subtitle: "Requests, bandwidth & threats",
                    icon: "chart.xyaxis.line",
                    color: .indigo,
                    destination: AnalyticsView(zoneId: zone.id, zoneName: zone.name)
                )
            }

            // ── DNS ──────────────────────────────────────────────────────
            Section(header: Text("DNS")) {
                ZoneNavRow(
                    title: "Records",
                    subtitle: "A, CNAME, MX, TXT and more",
                    icon: "server.rack",
                    color: .blue,
                    destination: DNSRecordsView(zoneId: zone.id, zoneName: zone.name)
                )
                ZoneNavRow(
                    title: "DNSSEC",
                    subtitle: "Sign DNS records to prevent spoofing",
                    icon: "lock.shield.fill",
                    color: .green,
                    destination: DNSSECView(zoneId: zone.id, zoneName: zone.name)
                )
            }

            // ── Security ─────────────────────────────────────────────────
            Section(header: Text("Security")) {
                ZoneNavRow(
                    title: "Security Events",
                    subtitle: "Firewall activity & triggered rules",
                    icon: "exclamationmark.shield.fill",
                    color: .purple,
                    destination: SecurityEventsView(zoneId: zone.id)
                )
                ZoneNavRow(
                    title: "WAF",
                    subtitle: "Custom rules, managed rules",
                    icon: "shield.lefthalf.filled",
                    color: .red,
                    destination: WAFCustomRulesView(zoneId: zone.id)
                )
                ZoneNavRow(
                    title: "Rate Limiting",
                    subtitle: "Throttle excessive request rates",
                    icon: "speedometer",
                    color: .orange,
                    destination: RateLimitingRulesView(zoneId: zone.id)
                )
                ZoneNavRow(
                    title: "IP Access Rules",
                    subtitle: "Allow or block by IP, ASN, country",
                    icon: "network.badge.shield.half.filled",
                    color: .blue,
                    destination: IPAccessRulesView(zoneId: zone.id)
                )
                ZoneNavRow(
                    title: "Settings",
                    subtitle: "Security level, Bot Fight Mode",
                    icon: "gear.badge.checkmark",
                    color: .gray,
                    destination: SecuritySettingsView(zoneId: zone.id)
                )
            }

            // ── SSL / TLS ────────────────────────────────────────────────
            Section(header: Text("SSL/TLS")) {
                ZoneNavRow(
                    title: "Overview",
                    subtitle: "Encryption mode & HTTPS settings",
                    icon: "lock.fill",
                    color: .orange,
                    destination: SSLSettingsView(zoneId: zone.id)
                )
                ZoneNavRow(
                    title: "Edge Certificates",
                    subtitle: "Universal, ACM & custom certificates",
                    icon: "doc.badge.gearshape.fill",
                    color: .orange,
                    destination: EdgeCertificatesView(zoneId: zone.id)
                )
            }

            // ── Performance ──────────────────────────────────────────────
            Section(header: Text("Performance")) {
                ZoneNavRow(
                    title: "Speed",
                    subtitle: "Minification, Brotli, HTTP/2",
                    icon: "bolt.fill",
                    color: .yellow,
                    destination: SpeedSettingsView(zoneId: zone.id)
                )
                ZoneNavRow(
                    title: "Caching",
                    subtitle: "Cache level, browser TTL, purge cache",
                    icon: "memorychip",
                    color: .cyan,
                    destination: CachingView(zoneId: zone.id)
                )
                ZoneNavRow(
                    title: "Rules",
                    subtitle: "Transform, Cache, Redirect, Snippets",
                    icon: "arrow.triangle.2.circlepath",
                    color: .teal,
                    destination: RulesHubView(zoneId: zone.id)
                )
            }

            // ── Network ──────────────────────────────────────────────────
            Section(header: Text("Network")) {
                ZoneNavRow(
                    title: "Network",
                    subtitle: "WebSockets, QUIC, gRPC",
                    icon: "network",
                    color: .purple,
                    destination: NetworkCenterView(zoneId: zone.id, zoneName: zone.name)
                )
                ZoneNavRow(
                    title: "Load Balancing",
                    subtitle: "Distribute traffic across origins",
                    icon: "arrow.triangle.branch",
                    color: .blue,
                    destination: LoadBalancerView(zoneId: zone.id)
                )
            }

            // ── Email ────────────────────────────────────────────────────
            Section(header: Text("Email")) {
                ZoneNavRow(
                    title: "Email Routing",
                    subtitle: "Forward addresses to your inbox",
                    icon: "envelope.fill",
                    color: .indigo,
                    destination: EmailRoutingView(zoneId: zone.id, zoneName: zone.name)
                )
            }

            // ── Content ──────────────────────────────────────────────────
            Section(header: Text("Content")) {
                ZoneNavRow(
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
                ZoneNavRow(
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
    }
}

// MARK: - ZoneHeaderCard

private struct ZoneHeaderCard: View {
    let zone: Zone

    private var isActive: Bool { zone.status == "active" }
    private var gradientColors: [Color] {
        isActive
            ? [Color(red: 0.07, green: 0.54, blue: 0.31), Color(red: 0.15, green: 0.72, blue: 0.50)]
            : [Color(red: 0.72, green: 0.35, blue: 0.0), Color(red: 0.85, green: 0.20, blue: 0.15)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ── Top Row: Domain Name + Plan & Type Badges ──────────────────
            HStack(alignment: .center, spacing: 8) {
                Text(zone.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 4)

                HStack(spacing: 5) {
                    if let planName = zone.plan?.displayName {
                        Text(planName.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(.white.opacity(0.22))
                            .clipShape(Capsule())
                    }

                    Text((zone.type ?? "full").uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .overlay(Capsule().stroke(.white.opacity(0.45), lineWidth: 0.8))
                }
                .fixedSize(horizontal: true, vertical: true)
            }

            // ── Compact Status Badges Row (Refined Mini Capsules) ──────────
            HStack(spacing: 6) {
                HStack(spacing: 3.5) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(zone.status.capitalized)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(.white.opacity(0.22))
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: true)

                if zone.paused {
                    Text("Paused")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color.red.opacity(0.70))
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: true)
                }

                if (zone.developmentMode ?? 0) > 0 {
                    Text("Dev Mode")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color.orange.opacity(0.85))
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: true)
                }

                Spacer()
            }

            // ── Nameservers Row ────────────────────────────────────────────
            if let nsArray = zone.nameServers, !nsArray.isEmpty {
                Divider().overlay(.white.opacity(0.25))
                
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.80))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Nameservers")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                        ForEach(nsArray, id: \.self) { ns in
                            Text(ns)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.95))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = nsArray.joined(separator: "\n")
                        ToastManager.shared.showCopied("Nameservers copied to clipboard")
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(5)
                            .background(.white.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .shadow(color: Color.green.opacity(0.20), radius: 10, x: 0, y: 4)
    }
}

// MARK: - QuickControlsSection

private struct QuickControlsSection: View {
    let zoneId: String

    @State private var isUnderAttack: Bool = false
    @State private var isDevMode: Bool = false
    @State private var isPaused: Bool
    @State private var isLoading: Bool = true
    @State private var hasFetchedData: Bool = false

    @State private var updatingAttack: Bool = false
    @State private var updatingDev: Bool = false
    @State private var updatingPause: Bool = false

    init(zoneId: String, initialPaused: Bool) {
        self.zoneId = zoneId
        self._isPaused = State(initialValue: initialPaused)
    }

    var body: some View {
        Section(header: Text("Quick Controls")) {
            // Under Attack Mode
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.body)
                    .foregroundStyle(isUnderAttack ? .white : .red)
                    .frame(width: 32, height: 32)
                    .background(isUnderAttack ? Color.red : Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Under Attack Mode")
                        .font(.body)
                    Text("5-second challenge for all visitors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if updatingAttack || isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Toggle("", isOn: $isUnderAttack)
                        .labelsHidden()
                        .onChange(of: isUnderAttack) { val in
                            guard hasFetchedData && !isLoading && !updatingAttack else { return }
                            HapticManager.impact(.light)
                            Task { await setUnderAttack(val) }
                        }
                }
            }
            .padding(.vertical, 2)

            // Development Mode
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.body)
                    .foregroundStyle(isDevMode ? .white : .orange)
                    .frame(width: 32, height: 32)
                    .background(isDevMode ? Color.orange : Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Development Mode")
                        .font(.body)
                    Text("Bypass cache for 3 hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if updatingDev || isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Toggle("", isOn: $isDevMode)
                        .labelsHidden()
                        .onChange(of: isDevMode) { val in
                            guard hasFetchedData && !isLoading && !updatingDev else { return }
                            HapticManager.impact(.light)
                            Task { await setDevMode(val) }
                        }
                }
            }
            .padding(.vertical, 2)

            // Pause Cloudflare
            HStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.body)
                    .foregroundStyle(isPaused ? .white : .secondary)
                    .frame(width: 32, height: 32)
                    .background(isPaused ? Color.secondary : Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Pause Cloudflare")
                        .font(.body)
                    Text("Route traffic directly to origin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if updatingPause {
                    ProgressView().controlSize(.small)
                } else {
                    Toggle("", isOn: $isPaused)
                        .labelsHidden()
                        .onChange(of: isPaused) { val in
                            guard hasFetchedData && !isLoading && !updatingPause else { return }
                            HapticManager.impact(.light)
                            Task { await setPaused(val) }
                        }
                }
            }
            .padding(.vertical, 2)
        }
        .task { await fetchInitialStates() }
    }

    // MARK: Fetch

    private func fetchInitialStates() async {
        if hasFetchedData { return }
        isLoading = true
        do {
            async let secSettings = SecuritySettingsService.shared.getSecuritySettings(zoneId: zoneId)
            async let cacheSettings = SpeedAndNetworkService.shared.getCachingSettings(zoneId: zoneId)
            let (sec, cache) = try await (secSettings, cacheSettings)
            isUnderAttack = (sec.level == "under_attack")
            isDevMode = cache.devMode
        } catch {
            // silently fail — toggles stay at defaults
        }
        isLoading = false
        hasFetchedData = true
    }

    // MARK: Mutations

    private func setUnderAttack(_ on: Bool) async {
        updatingAttack = true
        do {
            try await SecuritySettingsService.shared.updateSecurityLevel(
                zoneId: zoneId,
                level: on ? "under_attack" : "medium"
            )
            ToastManager.shared.showSuccess("Under Attack Mode", message: on ? "Enabled (5s challenge active)" : "Disabled")
        } catch {
            isUnderAttack = !on
            ToastManager.shared.showError("Failed to update Under Attack Mode")
        }
        updatingAttack = false
    }

    private func setDevMode(_ on: Bool) async {
        updatingDev = true
        do {
            try await SpeedAndNetworkService.shared.updateDevelopmentMode(
                zoneId: zoneId,
                isOn: on
            )
            NotificationCenter.default.post(name: .zoneUpdated, object: nil)
            ToastManager.shared.showSuccess("Development Mode", message: on ? "Enabled (Cache bypassed for 3h)" : "Disabled")
        } catch {
            isDevMode = !on
            ToastManager.shared.showError("Failed to update Development Mode")
        }
        updatingDev = false
    }

    private func setPaused(_ on: Bool) async {
        updatingPause = true
        do {
            try await ZoneService.shared.updateZoneStatus(zoneId: zoneId, paused: on)
            NotificationCenter.default.post(name: .zoneUpdated, object: nil)
            ToastManager.shared.showSuccess("Zone Status", message: on ? "Domain paused on Cloudflare" : "Domain active on Cloudflare")
        } catch {
            isPaused = !on
            ToastManager.shared.showError("Failed to update Zone Status")
        }
        updatingPause = false
    }
}

// MARK: - ZoneNavRow

struct ZoneNavRow<Destination: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 3)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Legacy helpers (kept for other views that may still use them)

struct MenuGroup<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                content
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }
}

struct FeatureRowContent: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                color.opacity(0.15)
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.body)
                    .accessibilityHidden(true)
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.body)
                .foregroundStyle(Color(UIColor.tertiaryLabel))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}
