import SwiftUI

// MARK: - ZoneHeaderCardView

struct ZoneHeaderCardView: View {
    let zone: Zone

    init(zone: Zone) {
        self.zone = zone
    }

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

            // ── Compact Status Badges Row ──────────────────────────────────
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
