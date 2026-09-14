import SwiftUI

// MARK: - Gentle Divider Component

/// A standardized ultra-gentle hairline divider matching the warm aesthetic.
/// Replaces arbitrary Rectangle() or system Divider() across cards and lists.
public struct GentleDivider: View {
    private let leadingInset: CGFloat
    private let trailingInset: CGFloat
    private let color: Color

    public init(
        leadingInset: CGFloat = 0,
        trailingInset: CGFloat = 0,
        color: Color = GentleColor.separator
    ) {
        self.leadingInset = leadingInset
        self.trailingInset = trailingInset
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 0.5)
            .padding(.leading, leadingInset)
            .padding(.trailing, trailingInset)
    }
}

/// Vertical hairline separator for juxtaposed metric stats inside cards.
public struct GentleVerticalDivider: View {
    private let height: CGFloat?
    private let color: Color

    public init(
        height: CGFloat? = nil,
        color: Color = GentleColor.separator
    ) {
        self.height = height
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 0.5, height: height)
    }
}
