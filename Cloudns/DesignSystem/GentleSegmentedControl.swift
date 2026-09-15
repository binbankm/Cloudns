import SwiftUI

// MARK: - Gentle Segmented Control (Sliding Capsule Pill)

/// Cozy sliding capsule segmented picker replacing raw technical pickers.
public struct GentleSegmentedControl<T: Hashable & CustomStringConvertible>: View {
    public let items: [T]
    @Binding public var selection: T
    @Namespace private var animationNamespace

    public init(items: [T], selection: Binding<T>) {
        self.items = items
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: GentleSpacing.xxs) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection == item
                Button {
                    withAnimation(GentleAnimation.spring) {
                        selection = item
                    }
                    GentleHaptics.selection()
                } label: {
                    Text(LocalizedStringKey(item.description))
                        .font(isSelected ? GentleTypography.bodyMedium : GentleTypography.body)
                        .foregroundStyle(isSelected ? GentleColor.accent : GentleColor.textSecondary)
                        .padding(.horizontal, GentleSpacing.sm)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: GentleCornerRadius.md, style: .continuous)
                                    .fill(GentleColor.cardSurface)
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                    .matchedGeometryEffect(id: "ActivePill", in: animationNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(GentleColor.cardSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.xl, style: .continuous))
    }
}
