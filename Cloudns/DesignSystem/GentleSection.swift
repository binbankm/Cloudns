import SwiftUI

// MARK: - Gentle Section Container Component

/// An ultra-gentle inset grouped section container that standardizes section titles,
/// trailing actions, card surface body, and explanatory footers.
public struct GentleSection<Content: View, Trailing: View>: View {
    private let title: String?
    private let footer: String?
    private let trailing: Trailing?
    private let content: Content

    public init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.trailing = trailing()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.xs) {
            // Header Row
            if title != nil || trailing != nil {
                HStack(alignment: .bottom) {
                    if let title = title {
                        Text(LocalizedStringKey(title))
                            .font(GentleTypography.captionSmall)
                            .foregroundStyle(GentleColor.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.6)
                    }

                    Spacer(minLength: GentleSpacing.sm)

                    if let trailing = trailing {
                        trailing
                    }
                }
                .padding(.horizontal, GentleSpacing.xs)
            }

            // Card Content
            content
                .gentleCard(variant: .elevated)

            // Footer Explanatory Text
            if let footer = footer {
                Text(LocalizedStringKey(footer))
                    .font(GentleTypography.footnote)
                    .foregroundStyle(GentleColor.textTertiary)
                    .lineSpacing(2)
                    .padding(.horizontal, GentleSpacing.xs)
            }
        }
        .padding(.horizontal, GentleSpacing.pageHorizontal)
        .padding(.vertical, GentleSpacing.xs)
    }
}

extension GentleSection where Trailing == EmptyView {
    public init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.trailing = nil
        self.content = content()
    }
}

// MARK: - Preview

#if DEBUG
struct GentleSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: GentleSpacing.md) {
                GentleSection(
                    title: "Domain Security",
                    footer: "DNSSEC protects your domain from DNS spoofing and cache poisoning."
                ) {
                    VStack(alignment: .leading, spacing: GentleSpacing.sm) {
                        Text("DNSSEC Status")
                            .font(GentleTypography.cardTitle)
                            .foregroundStyle(GentleColor.textPrimary)
                        Text("Active & cryptographically verified")
                            .font(GentleTypography.body)
                            .foregroundStyle(GentleColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GentleSection(
                    title: "Quick Actions",
                    trailing: {
                        Button("Manage") {}
                            .font(GentleTypography.captionSmall)
                            .foregroundStyle(GentleColor.accent)
                    }
                ) {
                    Text("Card with trailing action")
                        .font(GentleTypography.body)
                        .foregroundStyle(GentleColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical)
        }
        .background(GentleColor.background)
    }
}
#endif
