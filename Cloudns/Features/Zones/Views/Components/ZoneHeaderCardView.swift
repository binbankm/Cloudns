import SwiftUI

// MARK: - ZoneHeaderCardView

struct ZoneHeaderCardView: View {
    // MARK: - Properties
    let zone: Zone
    @State private var showingPurgeAlert = false
    @State private var isPurging = false

    init(zone: Zone) {
        self.zone = zone
    }

    private var isActive: Bool { zone.status == "active" }
    private var gradientColors: [Color] {
        isActive
            ? [CloudnsColor.success, CloudnsColor.success.opacity(0.8)]
            : [CloudnsColor.warning, CloudnsColor.danger]
    }

    private var statusDisplayText: LocalizedStringKey {
        switch zone.status.lowercased() {
        case "active":
            return "Active"
        case "pending":
            return "Pending"
        case "initializing":
            return "Initializing"
        case "moved":
            return "Moved"
        case "deleted":
            return "Deleted"
        case "deactivated":
            return "Deactivated"
        default:
            return LocalizedStringKey(zone.status.capitalized)
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            // ── Top Row: Domain Name + Plan & Type Badges ──────────────────
            HStack(alignment: .center, spacing: CloudnsSpacing.sm) {
                Text(zone.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: CloudnsSpacing.xs)

                HStack(spacing: 5) {
                    if let planName = zone.plan?.displayName {
                        Text(planName.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, CloudnsSpacing.sm)
                            .padding(.vertical, CloudnsSpacing.xxs)
                            .background(.white.opacity(0.22))
                            .clipShape(Capsule())
                    }

                    Text((zone.type ?? "full").uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xxs)
                        .overlay(Capsule().stroke(.white.opacity(0.45), lineWidth: 0.8))
                }
                .fixedSize(horizontal: true, vertical: true)
            }

            // ── Compact Status Badges & Quick Purge Row ────────────────────
            HStack(spacing: CloudnsSpacing.sm) {
                HStack(spacing: 3.5) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.caption2.weight(.semibold))
                    Text(statusDisplayText)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, CloudnsSpacing.sm)
                .padding(.vertical, CloudnsSpacing.xxs)
                .background(.white.opacity(0.22))
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: true)

                if zone.paused {
                    Text("Paused")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xxs)
                        .background(CloudnsColor.danger.opacity(0.70))
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: true)
                }

                if (zone.developmentMode ?? 0) > 0 {
                    Text("Dev Mode")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xxs)
                        .background(CloudnsColor.brandAccent.opacity(0.85))
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: true)
                }

                Spacer()
                
                // ⚡ 1-Tap Quick Purge Cache Button
                Button {
                    HapticManager.impact(.medium)
                    showingPurgeAlert = true
                } label: {
                    HStack(spacing: CloudnsSpacing.xs) {
                        if isPurging {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.caption2.weight(.bold))
                        }
                        Text("Purge Cache")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, CloudnsSpacing.sm)
                    .padding(.vertical, CloudnsSpacing.xs)
                    .background(.white.opacity(0.25))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isPurging)
            }

            // ── Nameservers Row ────────────────────────────────────────────
            if let nsArray = zone.nameServers, !nsArray.isEmpty {
                Divider().overlay(.white.opacity(0.25))
                
                HStack(alignment: .center, spacing: CloudnsSpacing.sm) {
                    Image(systemName: "server.rack")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.80))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Nameservers")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))
                        ForEach(nsArray, id: \.self) { ns in
                            Text(ns)
                                .font(.caption.monospaced())
                                .foregroundStyle(.white.opacity(0.95))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = nsArray.joined(separator: "\n")
                        CloudnsToastManager.shared.showCopied("Nameservers copied to clipboard")
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(CloudnsSpacing.xs)
                            .background(.white.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous))
        .padding(.horizontal, CloudnsSpacing.md)
        .padding(.vertical, CloudnsSpacing.sm)
        .cloudnsShadow(.brand(color: CloudnsColor.success, radius: 10, y: 4))
        .alert("Purge Everything?", isPresented: $showingPurgeAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Purge All Files", role: .destructive) {
                Task {
                    await performQuickPurge()
                }
            }
        } message: {
            Text("This will immediately expire and clear all cached static files globally across Cloudflare edge data centers for \(zone.name).")
        }
    }
    
    // MARK: - Actions
    private func performQuickPurge() async {
        isPurging = true
        HapticManager.impact(.heavy)
        do {
            try await ZoneService.shared.purgeCache(zoneId: zone.id)
            HapticManager.notification(.success)
            CloudnsToastManager.shared.showSuccess("Cache Purged", message: "All cached resources were purged successfully.")
        } catch {
            HapticManager.notification(.error)
            CloudnsToastManager.shared.showError("Purge Failed", message: error.localizedDescription)
        }
        isPurging = false
    }
}
