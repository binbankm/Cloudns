import SwiftUI

// MARK: - Gentle List Row Component

/// A standardized list row for cards, settings, and navigation sheets.
/// Supports leading icon tiles, titles, subtitles, values, and chevron accessories.
public struct GentleListRow<Leading: View, Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let value: String?
    private let showDivider: Bool
    private let showChevron: Bool
    private let action: (() -> Void)?
    private let leading: Leading?
    private let trailing: Trailing?

    public init(
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        showDivider: Bool = false,
        showChevron: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.showDivider = showDivider
        self.showChevron = showChevron
        self.action = action
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        VStack(spacing: 0) {
            contentRow

            if showDivider {
                GentleDivider(leadingInset: leading != nil ? 44 : GentleSpacing.md)
            }
        }
    }

    @ViewBuilder
    private var contentRow: some View {
        if let action {
            Button {
                GentleHaptics.selection()
                action()
            } label: {
                rowLayout
            }
            .buttonStyle(RowPressStyle())
        } else {
            rowLayout
        }
    }

    private var rowLayout: some View {
        HStack(spacing: GentleSpacing.sm) {
            // Leading Accessory
            if let leading {
                leading
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: GentleSpacing.micro) {
                Text(LocalizedStringKey(title))
                    .font(GentleTypography.bodyMedium)
                    .foregroundStyle(GentleColor.textPrimary)
                    .lineLimit(1)

                if let subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(GentleTypography.footnote)
                        .foregroundStyle(GentleColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: GentleSpacing.xs)

            // Trailing Value or Custom Accessory
            HStack(spacing: GentleSpacing.xs) {
                if let value {
                    Text(LocalizedStringKey(value))
                        .font(GentleTypography.callout)
                        .foregroundStyle(GentleColor.textSecondary)
                        .lineLimit(1)
                }

                if let trailing {
                    trailing
                }

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(GentleTypography.caption.weight(.semibold))
                        .foregroundStyle(GentleColor.textTertiary)
                }
            }
        }
        .padding(.vertical, GentleSpacing.sm)
        .padding(.horizontal, GentleSpacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Initializer Convenience Overloads

public extension GentleListRow where Leading == EmptyView, Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        showDivider: Bool = false,
        showChevron: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.showDivider = showDivider
        self.showChevron = showChevron
        self.action = action
        leading = nil
        trailing = nil
    }
}

public extension GentleListRow where Leading: View, Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        showDivider: Bool = false,
        showChevron: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.showDivider = showDivider
        self.showChevron = showChevron
        self.action = action
        self.leading = leading()
        trailing = nil
    }
}

public extension GentleListRow where Leading == EmptyView, Trailing: View {
    init(
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        showDivider: Bool = false,
        showChevron: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.showDivider = showDivider
        self.showChevron = showChevron
        self.action = action
        leading = nil
        self.trailing = trailing()
    }
}

// MARK: - Row Press Style

private struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? GentleColor.cardSurfaceSecondary.opacity(0.5)
                    : Color.clear
            )
            .animation(GentleAnimation.snappy, value: configuration.isPressed)
    }
}

// MARK: - Icon Tile Helper

/// A rounded square icon tile commonly used as the leading view in settings or list rows.
public struct GentleIconTile: View {
    private let systemName: String
    private let tint: Color
    private let background: Color
    private let size: CGFloat

    public init(
        systemName: String,
        tint: Color = GentleColor.accent,
        background: Color? = nil,
        size: CGFloat = 30
    ) {
        self.systemName = systemName
        self.tint = tint
        self.background = background ?? tint.opacity(0.14)
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: GentleCornerRadius.sm, style: .continuous)
                .fill(background)
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(GentleTypography.subheadlineSemibold)
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Preview

#if DEBUG
    struct GentleListRow_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: GentleSpacing.md) {
                VStack(spacing: 0) {
                    GentleListRow(
                        title: "Audit Logs",
                        subtitle: "View recent Cloudflare API actions",
                        showDivider: true,
                        showChevron: true,
                        action: {},
                        leading: {
                            GentleIconTile(systemName: "list.bullet.rectangle", tint: GentleColor.accent)
                        }
                    )

                    GentleListRow(
                        title: "Security Level",
                        value: "Medium",
                        showDivider: true,
                        showChevron: true,
                        action: {},
                        leading: {
                            GentleIconTile(systemName: "shield.lefthalf.filled", tint: GentleColor.sageGreen)
                        }
                    )

                    GentleListRow(
                        title: "Development Mode",
                        subtitle: "Bypass cache for 3 hours",
                        showDivider: false,
                        leading: {
                            GentleIconTile(systemName: "hammer.fill", tint: GentleColor.apricotGold)
                        },
                        trailing: {
                            Toggle(isOn: .constant(true)) {
                                EmptyView()
                            }
                            .labelsHidden()
                            .gentleToggle()
                        }
                    )
                }
                .gentleCard()
            }
            .padding()
            .background(GentleColor.background)
        }
    }
#endif
