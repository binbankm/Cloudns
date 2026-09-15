import SwiftUI

// MARK: - HealthRingCard (Warm Amber Health Status Card)

struct HealthRingCard: View {
    let healthPercentage: Double
    let activeCount: Int
    let totalCount: Int
    let pendingCount: Int
    var pausedCount: Int = 0

    @ViewBuilder
    private var statusDescriptionView: some View {
        if totalCount == 0 {
            Text("No domains connected")
        } else if pendingCount > 0 {
            Text("\(pendingCount) Pending Review")
        } else if pausedCount > 0 {
            Text("\(pausedCount) Paused")
        } else if healthPercentage >= 100 {
            Text("All Systems Normal")
        } else {
            Text("Action Needed")
        }
    }

    private var statusDotColor: Color {
        if pendingCount > 0 || pausedCount > 0 {
            return GentleColor.statusWarning
        }
        return GentleColor.statusActive
    }

    var body: some View {
        HStack(spacing: GentleSpacing.lg) {
            // MARK: - DesignSystem Circular Health Ring

            GentleRingView(
                progress: totalCount > 0 ? (healthPercentage / 100.0) : 0.0,
                lineWidth: GentleSpacing.xs,
                diameter: 76,
                label: "Health"
            )
            .padding(.leading, GentleSpacing.xs)

            // MARK: - Metric Details

            VStack(alignment: .leading, spacing: GentleSpacing.xs) {
                HStack(spacing: GentleSpacing.xs) {
                    Circle()
                        .fill(statusDotColor)
                        .frame(width: GentleSpacing.xs, height: GentleSpacing.xs)

                    statusDescriptionView
                        .font(GentleTypography.subheadlineBold)
                        .foregroundStyle(GentleColor.textPrimary)
                        .lineLimit(1)
                }

                Text("\(activeCount) of \(totalCount) domains active")
                    .font(GentleTypography.footnote)
                    .foregroundStyle(GentleColor.textSecondary)

                // Only display contextual issue badges when issues exist
                if pendingCount > 0 || pausedCount > 0 {
                    HStack(spacing: GentleSpacing.sm) {
                        if pendingCount > 0 {
                            GentleBadge(
                                "\(pendingCount) Pending",
                                iconName: "clock.arrow.circlepath",
                                type: .warning
                            )
                        }

                        if pausedCount > 0 {
                            GentleBadge(
                                "\(pausedCount) Paused",
                                iconName: "pause.fill",
                                type: .danger
                            )
                        }
                    }
                    .padding(.top, GentleSpacing.micro)
                }
            }

            Spacer()
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
    }
}

#Preview {
    VStack(spacing: GentleSpacing.md) {
        HealthRingCard(
            healthPercentage: 100.0,
            activeCount: 25,
            totalCount: 25,
            pendingCount: 0,
            pausedCount: 0
        )

        HealthRingCard(
            healthPercentage: 88.0,
            activeCount: 22,
            totalCount: 25,
            pendingCount: 2,
            pausedCount: 1
        )
    }
    .padding()
    .padding()
}
