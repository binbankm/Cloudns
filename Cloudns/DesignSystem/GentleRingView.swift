import SwiftUI

// MARK: - Gentle Ring View (Health Ring & Activity Overview)

/// Animated circular health/activity ring used for Zone health overview and analytics.
public struct GentleRingView: View {
    public var progress: Double // 0.0 to 1.0
    public var lineWidth: CGFloat
    public var diameter: CGFloat
    public var tintColor: Color
    public var secondaryTintColor: Color
    public var label: String?

    public init(
        progress: Double,
        lineWidth: CGFloat = 12,
        diameter: CGFloat = 110,
        tintColor: Color = GentleColor.accent,
        secondaryTintColor: Color = GentleColor.accentSecondary,
        label: String? = "Health"
    ) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.lineWidth = lineWidth
        self.diameter = diameter
        self.tintColor = tintColor
        self.secondaryTintColor = secondaryTintColor
        self.label = label
    }

    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(
                    tintColor.opacity(0.12),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)

            // Progress Arc
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: [tintColor, secondaryTintColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: diameter, height: diameter)
                .animation(GentleAnimation.spring, value: progress)

            // Center metric slot
            VStack(spacing: 1) {
                Text(verbatim: "\(Int(progress * 100))%")
                    .font(diameter <= 80 ? .system(size: 16, weight: .bold, design: .rounded) : GentleTypography.metricMedium)
                    .foregroundStyle(GentleColor.textPrimary)
                    .monospacedDigit()

                if let label, !label.isEmpty {
                    Text(LocalizedStringKey(label))
                        .font(GentleTypography.captionSmall)
                        .foregroundStyle(GentleColor.textSecondary)
                }
            }
        }
        .frame(width: diameter + lineWidth, height: diameter + lineWidth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedStringKey(label ?? "Health")))
        .accessibilityValue(Text(verbatim: "\(Int(progress * 100))%"))
    }
}
