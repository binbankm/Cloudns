import SwiftUI

// MARK: - Gentle Progress & Activity Indicators

/// An ultra-gentle, warm-tinted spinning activity indicator for buttons and inline rows.
public struct GentleSpinner: View {
    public let tint: Color
    public let size: CGFloat
    public let lineWidth: CGFloat

    @State private var isSpinning: Bool = false

    public init(
        tint: Color = GentleColor.accent,
        size: CGFloat = 20,
        lineWidth: CGFloat = 2.5
    ) {
        self.tint = tint
        self.size = size
        self.lineWidth = lineWidth
    }

    public var body: some View {
        Circle()
            .trim(from: 0.15, to: 0.85)
            .stroke(
                tint,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(
                Animation.linear(duration: 0.9).repeatForever(autoreverses: false),
                value: isSpinning
            )
            .onAppear {
                isSpinning = true
            }
            .accessibilityLabel(Text("Loading"))
    }
}

/// A cozy rounded progress bar with animated spring transitions.
public struct GentleProgressBar: View {
    public let value: Double
    public let total: Double
    public let tint: Color
    public let height: CGFloat

    public init(
        value: Double,
        total: Double = 1.0,
        tint: Color = GentleColor.accent,
        height: CGFloat = 6
    ) {
        self.value = value
        self.total = total
        self.tint = tint
        self.height = height
    }

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0.0), 1.0)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.15))
                    .frame(height: height)

                Capsule()
                    .fill(tint)
                    .frame(
                        width: max(geometry.size.width * CGFloat(percentage), height),
                        height: height
                    )
                    .animation(GentleAnimation.spring, value: percentage)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(Text("\(Int(percentage * 100)) percent"))
    }
}
