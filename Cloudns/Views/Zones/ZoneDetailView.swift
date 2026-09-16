import SwiftUI

// MARK: - ZoneDetailView (Ultra-Gentle Domain Management Hub)

struct ZoneDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ZoneDetailViewModel

    init(zone: Zone) {
        _viewModel = StateObject(wrappedValue: ZoneDetailViewModel(zone: zone))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: GentleSpacing.md) {
                // Section 1: Compact Hero Identity Card
                heroIdentityCard

                // Section 2: Ultra-Compact Quick Toolbar (1 Row, 3 Columns)
                quickOperationsToolbar

                // Section 3: Core Capabilities Navigation Hub
                capabilitiesNavigationHub

                // Section 4: Protection & Danger Zone
                dangerZoneSection
            }
            .padding(.horizontal, GentleSpacing.lg)
            .padding(.vertical, GentleSpacing.md)
        }
        .gentleCanvas()
        .navigationTitle(viewModel.zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadInitialData()
        }
        .confirmationDialog(
            "Purge Cache",
            isPresented: $viewModel.showPurgeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Purge Everything", role: .destructive) {
                Task {
                    await viewModel.purgeEverythingCache()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Purging cache will force Cloudflare to fetch all assets from your origin server. This may temporarily increase server load.")
        }
        .confirmationDialog(
            "Delete Domain",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Domain", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteZone()
                        dismiss()
                    } catch {
                        // Handled in viewModel
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(viewModel.zone.name)? DNS routing will stop immediately and cannot be undone.")
        }
    }

    // MARK: - Section 1: Domain Hero Identity Card

    private var heroIdentityCard: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.md) {
            // Row 1: Domain Globe Icon + Title + Status Badge
            HStack(alignment: .center, spacing: GentleSpacing.sm) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(GentleTypography.titleSection)
                    .foregroundStyle(GentleColor.accent)
                    .frame(width: GentleSpacing.iconLarge, height: GentleSpacing.iconLarge)
                    .background(GentleColor.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.md, style: .continuous))

                Text(viewModel.zone.name)
                    .font(GentleTypography.titleSection)
                    .foregroundStyle(GentleColor.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: GentleSpacing.xs)

                statusBadge
            }

            // Row 2: Plan Tag • Mode Tag • Zone ID with Copy
            HStack(spacing: GentleSpacing.xs) {
                Text(LocalizedStringKey(viewModel.zone.plan?.displayName ?? "Free"))
                    .font(GentleTypography.caption)
                    .foregroundStyle(GentleColor.accent)
                    .padding(.horizontal, GentleSpacing.xs)
                    .padding(.vertical, GentleSpacing.micro)
                    .background(GentleColor.accent.opacity(0.1))
                    .clipShape(Capsule())

                Text(LocalizedStringKey(viewModel.zone.type?.capitalized ?? "Full"))
                    .font(GentleTypography.caption)
                    .foregroundStyle(GentleColor.textSecondary)
                    .padding(.horizontal, GentleSpacing.xs)
                    .padding(.vertical, GentleSpacing.micro)
                    .background(GentleColor.cardSurfaceSecondary)
                    .clipShape(Capsule())

                Spacer()

                Button {
                    copyZoneId()
                } label: {
                    HStack(spacing: GentleSpacing.xxs) {
                        Text(verbatim: "ID: \(String(viewModel.zone.id.prefix(8)))…")
                            .font(GentleTypography.caption)
                            .foregroundStyle(GentleColor.textSecondary)

                        Image(systemName: "doc.on.doc")
                            .font(GentleTypography.captionSmall)
                            .foregroundStyle(GentleColor.textSecondary.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
            }

            // Row 3: Nameservers Section (上下完整显示两个权威名称服务器)
            nameserversBox
        }
        .gentleCardStyle(variant: .elevated, cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
    }

    private var nameserversBox: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.xs) {
            if !viewModel.nameservers.isEmpty {
                ForEach(Array(viewModel.nameservers.prefix(2).enumerated()), id: \.element) { index, ns in
                    HStack(spacing: GentleSpacing.xs) {
                        Image(systemName: "server.rack")
                            .font(GentleTypography.captionSmall)
                            .foregroundStyle(GentleColor.textSecondary.opacity(0.7))

                        Text(verbatim: "NS \(index + 1): \(ns)")
                            .font(GentleTypography.caption)
                            .foregroundStyle(GentleColor.textPrimary)
                            .lineLimit(1)

                        Spacer(minLength: GentleSpacing.xxs)

                        Button {
                            copySingleNameserver(ns)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(GentleTypography.captionSmall)
                                .foregroundStyle(GentleColor.textSecondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                HStack(spacing: GentleSpacing.xs) {
                    Image(systemName: "server.rack")
                        .font(GentleTypography.captionSmall)
                        .foregroundStyle(GentleColor.textSecondary.opacity(0.7))

                    Text("No Nameservers Assigned")
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary)
                }
            }

            // If pending, show activation check button
            if viewModel.zone.zoneStatus == .pending {
                Divider()
                    .padding(.vertical, GentleSpacing.micro)
                    .opacity(0.5)

                HStack {
                    Text("Pending nameserver verification")
                        .font(GentleTypography.captionSmall)
                        .foregroundStyle(GentleColor.statusWarning)

                    Spacer()

                    Button {
                        Task {
                            await viewModel.checkActivation()
                        }
                    } label: {
                        HStack(spacing: GentleSpacing.xxs) {
                            if viewModel.isCheckingActivation {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(GentleTypography.captionSmall)
                            }
                            Text("Check NS")
                                .font(GentleTypography.caption)
                        }
                        .foregroundStyle(GentleColor.statusWarning)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isCheckingActivation)
                }
            }
        }
        .padding(.horizontal, GentleSpacing.sm)
        .padding(.vertical, GentleSpacing.xs)
        .background(GentleColor.cardSurfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous))
    }

    private var statusBadge: some View {
        GentleBadge(
            viewModel.isPaused ? "Paused" : viewModel.zone.zoneStatus.displayName,
            iconName: viewModel.isPaused ? "pause.fill" : (viewModel.zone.zoneStatus == .active ? "checkmark" : "clock"),
            type: viewModel.isPaused ? .danger : (viewModel.zone.zoneStatus == .active ? .active : .warning)
        )
    }

    // MARK: - Section 2: Quick Operations (Three Distinct Gentle Cards)

    private var quickOperationsToolbar: some View {
        HStack(spacing: GentleSpacing.sm) {
            // 1. Under Attack Mode
            quickActionCard(
                iconName: "shield.lefthalf.filled",
                title: "Under Attack",
                subtitle: viewModel.isUnderAttack ? "Active" : "Off",
                isActive: viewModel.isUnderAttack,
                activeColor: GentleColor.statusDanger
            ) {
                Task {
                    await viewModel.toggleUnderAttack()
                }
            }

            // 2. Dev Mode
            quickActionCard(
                iconName: "bolt.fill",
                title: "Dev Mode",
                subtitle: viewModel.isDevelopmentMode ? "Active" : "Off",
                isActive: viewModel.isDevelopmentMode,
                activeColor: GentleColor.accent
            ) {
                Task {
                    await viewModel.toggleDevelopmentMode()
                }
            }

            // 3. Purge Cache
            quickActionCard(
                iconName: "trash",
                title: "Purge Cache",
                subtitle: "Instant",
                isActive: false,
                activeColor: GentleColor.textSecondary
            ) {
                GentleHaptics.selection()
                viewModel.showPurgeConfirmation = true
            }
        }
    }

    private func quickActionCard(
        iconName: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        isActive: Bool,
        activeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: GentleSpacing.xxs) {
                Image(systemName: iconName)
                    .font(GentleTypography.subheadlineBold)
                    .foregroundStyle(isActive ? activeColor : GentleColor.textSecondary)
                    .frame(width: GentleSpacing.iconSmall, height: GentleSpacing.iconSmall)
                    .background(
                        (isActive ? activeColor : GentleColor.cardSurfaceSecondary)
                            .opacity(isActive ? 0.16 : 0.8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.sm, style: .continuous))

                VStack(spacing: GentleSpacing.micro) {
                    Text(title)
                        .font(GentleTypography.captionMedium)
                        .foregroundStyle(GentleColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(subtitle)
                        .font(GentleTypography.captionSmall)
                        .foregroundStyle(isActive ? activeColor : GentleColor.textSecondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GentleSpacing.xs)
            .padding(.horizontal, GentleSpacing.xxs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .gentleCardStyle(
            variant: .elevated,
            cornerRadius: GentleCornerRadius.lg,
            padding: 0
        )
    }

    // MARK: - Section 3: Core Capabilities Navigation Hub

    private var capabilitiesNavigationHub: some View {
        VStack(spacing: 0) {
            // 1. DNS Records & DNSSEC -> Connects to existing DNSRecordsView
            NavigationLink {
                DNSRecordsView(zone: viewModel.zone)
            } label: {
                capabilityRow(
                    iconName: "globe",
                    iconColor: GentleColor.accent,
                    title: "DNS Records & DNSSEC",
                    summary: "Manage records, proxy routing & DNSSEC signing"
                )
            }
            .buttonStyle(.plain)

            dividerLine

            // 2. SSL / TLS & Certificates
            NavigationLink {
                Text("SSL / TLS Settings Coming in Step 3")
                    .gentleCanvas()
            } label: {
                capabilityRow(
                    iconName: "lock.shield",
                    iconColor: GentleColor.statusActive,
                    title: "SSL / TLS Encryption",
                    summary: "Edge & origin encryption modes and certificates"
                )
            }
            .buttonStyle(.plain)

            dividerLine

            // 3. Security, WAF & Event Telemetry
            NavigationLink {
                Text("Security & WAF Coming in Step 4")
                    .gentleCanvas()
            } label: {
                capabilityRow(
                    iconName: "shield.fill",
                    iconColor: GentleColor.statusWarning,
                    title: "Security & WAF Protection",
                    summary: "Firewall rules, bot fighting & threat defense"
                )
            }
            .buttonStyle(.plain)

            dividerLine

            // 4. Speed, Caching & Protocols
            NavigationLink {
                Text("Speed & Optimization Coming in Step 5")
                    .gentleCanvas()
            } label: {
                capabilityRow(
                    iconName: "speedometer",
                    iconColor: GentleColor.accent,
                    title: "Speed, Caching & Network",
                    summary: "Cache optimization, Brotli compression & HTTP/3"
                )
            }
            .buttonStyle(.plain)

            dividerLine

            // 5. Traffic Rules & Load Balancing
            NavigationLink {
                Text("Traffic Rules Coming in Step 6")
                    .gentleCanvas()
            } label: {
                capabilityRow(
                    iconName: "arrow.triangle.branch",
                    iconColor: GentleColor.textSecondary,
                    title: "Rules & Load Balancing",
                    summary: "Page rules, URL redirects & load balancing pools"
                )
            }
            .buttonStyle(.plain)

            dividerLine

            // 6. Custom Email Routing
            NavigationLink {
                Text("Email Routing Coming in Step 7")
                    .gentleCanvas()
            } label: {
                capabilityRow(
                    iconName: "envelope.badge",
                    iconColor: GentleColor.statusActive,
                    title: "Email Routing",
                    summary: "Custom domain addresses & seamless forwarding"
                )
            }
            .buttonStyle(.plain)

            dividerLine

            // 7. Domain Analytics & Telemetry
            NavigationLink {
                Text("Domain Analytics Coming in Step 8")
                    .gentleCanvas()
            } label: {
                capabilityRow(
                    iconName: "chart.xyaxis.line",
                    iconColor: GentleColor.accent,
                    title: "Domain Analytics",
                    summary: "Real-time traffic, request telemetry & security insights"
                )
            }
            .buttonStyle(.plain)
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: 0)
    }

    private func capabilityRow(
        iconName: String,
        iconColor: Color,
        title: LocalizedStringKey,
        summary: LocalizedStringKey
    ) -> some View {
        HStack(spacing: GentleSpacing.sm) {
            Image(systemName: iconName)
                .font(GentleTypography.subheadlineBold)
                .foregroundStyle(iconColor)
                .frame(width: GentleSpacing.iconSmall, height: GentleSpacing.iconSmall)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous))

            VStack(alignment: .leading, spacing: GentleSpacing.micro) {
                Text(title)
                    .font(GentleTypography.bodyMedium)
                    .foregroundStyle(GentleColor.textPrimary)

                Text(summary)
                    .font(GentleTypography.caption)
                    .foregroundStyle(GentleColor.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(GentleTypography.captionSmall)
                .foregroundStyle(GentleColor.textSecondary.opacity(0.4))
        }
        .padding(.horizontal, GentleSpacing.md)
        .padding(.vertical, GentleSpacing.sm)
        .contentShape(Rectangle())
    }

    private var dividerLine: some View {
        Divider()
            .padding(.leading, GentleSpacing.huge)
            .opacity(0.6)
    }

    // MARK: - Section 4: Protection & Danger Zone

    private var dangerZoneSection: some View {
        VStack(spacing: GentleSpacing.sm) {
            // Zone Hold Toggle Row
            HStack {
                VStack(alignment: .leading, spacing: GentleSpacing.micro) {
                    HStack(spacing: GentleSpacing.xs) {
                        Text("Zone Hold Protection")
                            .font(GentleTypography.bodyMedium)
                            .foregroundStyle(GentleColor.textPrimary)

                        if !viewModel.isEnterprise {
                            GentleBadge("Enterprise", type: .warning)
                        }
                    }

                    Text("Lock domain against unauthorized transfers")
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary)
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { viewModel.isZoneHoldEnabled },
                    set: { _ in
                        Task {
                            await viewModel.toggleZoneHold()
                        }
                    }
                )) {
                    EmptyView()
                }
                .labelsHidden()
                .tint(GentleColor.accent)
                .disabled(!viewModel.isEnterprise)
                .opacity(viewModel.isEnterprise ? 1.0 : 0.5)
            }
            .padding(.horizontal, GentleSpacing.md)
            .padding(.vertical, GentleSpacing.sm)
            .contentShape(Rectangle())
            .onTapGesture {
                if !viewModel.isEnterprise {
                    Task {
                        await viewModel.toggleZoneHold()
                    }
                }
            }
            .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: 0)

            // Pause Cloudflare Proxy Row
            HStack {
                VStack(alignment: .leading, spacing: GentleSpacing.micro) {
                    Text("Pause Cloudflare on Site")
                        .font(GentleTypography.bodyMedium)
                        .foregroundStyle(GentleColor.textPrimary)

                    Text("Route traffic directly to origin for troubleshooting")
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary)
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { viewModel.isPaused },
                    set: { newValue in
                        Task {
                            await viewModel.setPaused(to: newValue)
                        }
                    }
                )) {
                    EmptyView()
                }
                .labelsHidden()
                .tint(GentleColor.statusWarning)
            }
            .padding(.horizontal, GentleSpacing.md)
            .padding(.vertical, GentleSpacing.sm)
            .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: 0)

            // Delete Domain Button
            Button {
                GentleHaptics.warning()
                viewModel.showDeleteConfirmation = true
            } label: {
                HStack(spacing: GentleSpacing.xs) {
                    Image(systemName: "trash")
                        .font(GentleTypography.subheadlineBold)

                    Text("Delete Domain from Cloudflare")
                        .font(GentleTypography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, GentleSpacing.sm)
            }
            .gentleDestructiveButton()
            .padding(.top, GentleSpacing.xs)
        }
    }

    // MARK: - Clipboard Helpers

    private func copyZoneId() {
        UIPasteboard.general.string = viewModel.zone.id
        GentleHaptics.selection()
        GentleBannerManager.shared.show(
            type: .success,
            title: "Zone ID Copied",
            message: viewModel.zone.id
        )
    }

    private func copyNameservers() {
        guard let ns = viewModel.zone.nameServers, !ns.isEmpty else { return }
        let text = ns.joined(separator: "\n")
        UIPasteboard.general.string = text
        GentleHaptics.selection()
        GentleBannerManager.shared.show(
            type: .success,
            title: "Nameservers Copied",
            message: text
        )
    }

    private func copySingleNameserver(_ text: String) {
        UIPasteboard.general.string = text
        GentleHaptics.selection()
        GentleBannerManager.shared.show(
            type: .success,
            title: "Nameserver Copied",
            message: text
        )
    }
}

#Preview {
    NavigationStack {
        ZoneDetailView(
            zone: Zone(
                id: "9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d",
                name: "baimao.work",
                status: "active",
                paused: false,
                type: "full",
                plan: ZonePlan(name: "Free"),
                nameServers: ["ashley.ns.cloudflare.com", "tony.ns.cloudflare.com"]
            )
        )
    }
}
