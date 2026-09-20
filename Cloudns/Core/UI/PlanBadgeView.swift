import SwiftUI

// MARK: - PlanBadgeView

/// Apple HIG compliant pill-style badge representing subscription plan tiers and unlock state.
public struct PlanBadgeView: View {
    public let title: String
    public let tintColor: Color
    public let isUnlocked: Bool

    // MARK: - Initializers

    /// Evaluates unlock state automatically based on required tier vs current zone tier
    public init(required: PlanTier, current: PlanTier) {
        self.title = required.shortBadge
        self.tintColor = Self.color(for: required)
        self.isUnlocked = current >= required
    }

    /// Custom title and unlock state (e.g. for ADD-ON or PAID feature badges)
    public init(title: String, tintColor: Color = .orange, isUnlocked: Bool) {
        self.title = title
        self.tintColor = tintColor
        self.isUnlocked = isUnlocked
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 3) {
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.secondary)
                    .transition(.scale.combined(with: .opacity))
            }

            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .textCase(.uppercase)
        }
        .foregroundStyle(isUnlocked ? tintColor : Color.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(
                    isUnlocked
                        ? tintColor.opacity(0.14)
                        : Color(uiColor: .tertiarySystemFill)
                )
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    isUnlocked
                        ? tintColor.opacity(0.28)
                        : Color.secondary.opacity(0.18),
                    lineWidth: 0.5
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isUnlocked)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isUnlocked ? "\(title) feature, unlocked" : "\(title) feature, locked")
    }

    // MARK: - Brand Colors

    public static func color(for tier: PlanTier) -> Color {
        switch tier {
        case .free:
            .secondary
        case .pro:
            .blue
        case .business:
            .purple
        case .enterprise:
            Color(red: 0.96, green: 0.65, blue: 0.12) // Amber Gold
        case .paid, .addOn:
            .orange
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        // Free user perspective (Pro/Biz/Ent locked)
        HStack(spacing: 8) {
            Text("Free Zone:")
            PlanBadgeView(required: .pro, current: .free)
            PlanBadgeView(required: .business, current: .free)
            PlanBadgeView(required: .enterprise, current: .free)
        }

        // Pro user perspective (Pro unlocked, Biz/Ent locked)
        HStack(spacing: 8) {
            Text("Pro Zone:")
            PlanBadgeView(required: .pro, current: .pro)
            PlanBadgeView(required: .business, current: .pro)
            PlanBadgeView(required: .enterprise, current: .pro)
        }

        // Add-on & Paid
        HStack(spacing: 8) {
            Text("Add-on & Paid:")
            PlanBadgeView(title: "ADD-ON", tintColor: .blue, isUnlocked: false)
            PlanBadgeView(title: "ADD-ON", tintColor: .blue, isUnlocked: true)
        }
    }
    .padding()
}
