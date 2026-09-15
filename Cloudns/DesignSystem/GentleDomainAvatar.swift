import SwiftUI

// MARK: - Gentle Domain Avatar (Monogram Squircle)

/// A deterministic pastel squircle avatar for domain names, displaying the uppercase initial letter
/// with Apple HIG continuous curvature and unified Gentle design tokens.
public struct GentleDomainAvatar: View {
    public enum Size {
        case small // 28pt (compact list, inline badge)
        case medium // 38pt (standard ZoneCardView)
        case large // 48pt (zone detail header, sheet hero)

        var dimension: CGFloat {
            switch self {
            case .small: 28
            case .medium: 38
            case .large: 48
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: GentleCornerRadius.sm
            case .medium: GentleCornerRadius.md
            case .large: GentleCornerRadius.lg
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: 13
            case .medium: 17
            case .large: 22
            }
        }
    }

    private let domain: String
    private let size: Size

    public init(domain: String, size: Size = .medium) {
        self.domain = domain
        self.size = size
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
            .fill(brandColor.opacity(0.14))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .stroke(brandColor.opacity(0.28), lineWidth: 0.8)
            )
            .frame(width: size.dimension, height: size.dimension)
            .overlay(
                Text(initialLetter)
                    .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(brandColor)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Domain: \(domain)"))
    }

    // MARK: - Helpers

    private var initialLetter: String {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let host = trimmed.hasPrefix("www.") ? String(trimmed.dropFirst(4)) : trimmed

        if let firstAlnum = host.first(where: { $0.isLetter || $0.isNumber }) {
            return String(firstAlnum).uppercased()
        }
        if let first = host.first {
            return String(first).uppercased()
        }
        return "D"
    }

    private var brandColor: Color {
        let cleaned = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let seed = abs(cleaned.hashValue)
        let palette: [Color] = [
            GentleColor.accent,
            GentleColor.sageGreen,
            GentleColor.skyBlue,
            GentleColor.peachOrange,
            GentleColor.lavender,
            GentleColor.apricotGold
        ]
        return palette[seed % palette.count]
    }
}

// MARK: - Preview

#if DEBUG
    struct GentleDomainAvatar_Previews: PreviewProvider {
        static var previews: some View {
            HStack(spacing: GentleSpacing.md) {
                GentleDomainAvatar(domain: "apple.com", size: .small)
                GentleDomainAvatar(domain: "cloudflare.com", size: .medium)
                GentleDomainAvatar(domain: "github.com", size: .medium)
                GentleDomainAvatar(domain: "google.com", size: .large)
            }
            .padding()
            .background(GentleColor.background)
        }
    }
#endif
