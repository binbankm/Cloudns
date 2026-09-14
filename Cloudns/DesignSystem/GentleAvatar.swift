import SwiftUI

// MARK: - Gentle Account Avatar Component

/// A deterministic pastel avatar for Cloudflare accounts, displaying initials
/// and an optional active indicator dot.
public struct GentleAvatar: View {
    public enum Size {
        case small    // 28pt (navigation bar, compact rows)
        case medium   // 36pt (standard list row, switcher items)
        case large    // 48pt (drawer header, card profile)
        case xlarge   // 64pt (settings hero, account detail)

        var dimension: CGFloat {
            switch self {
            case .small: return 28
            case .medium: return 36
            case .large: return 48
            case .xlarge: return 64
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 15
            case .large: return 20
            case .xlarge: return 26
            }
        }

        var indicatorSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            case .xlarge: return 14
            }
        }
    }

    private let name: String
    private let email: String?
    private let size: Size
    private let isActive: Bool

    public init(
        name: String,
        email: String? = nil,
        size: Size = .medium,
        isActive: Bool = false
    ) {
        self.name = name
        self.email = email
        self.size = size
        self.isActive = isActive
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar Surface
            Circle()
                .fill(avatarColor.opacity(0.18))
                .overlay(
                    Circle()
                        .stroke(avatarColor.opacity(0.35), lineWidth: 1)
                )
                .frame(width: size.dimension, height: size.dimension)
                .overlay(
                    Text(initials)
                        .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(avatarColor)
                )

            // Active Dot Indicator
            if isActive {
                Circle()
                    .fill(GentleColor.statusActive)
                    .frame(width: size.indicatorSize, height: size.indicatorSize)
                    .overlay(
                        Circle()
                            .stroke(GentleColor.cardSurface, lineWidth: 2)
                    )
                    .offset(x: 1, y: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Account: \(name)"))
        .accessibilityValue(isActive ? Text("Active account") : Text(verbatim: ""))
    }

    // MARK: - Helpers

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let components = trimmed.components(separatedBy: .whitespaces)
            if components.count >= 2,
               let first = components[0].first,
               let second = components[1].first {
                return "\(first)\(second)".uppercased()
            } else if let first = trimmed.first {
                return String(first).uppercased()
            }
        }

        if let email = email, let first = email.first {
            return String(first).uppercased()
        }

        return "CF"
    }

    private var avatarColor: Color {
        let seed = abs((name + (email ?? "")).hashValue)
        let palette: [Color] = [
            GentleColor.accent,
            GentleColor.sageGreen,
            GentleColor.peachOrange,
            GentleColor.skyBlue,
            GentleColor.lavender,
            GentleColor.apricotGold
        ]
        return palette[seed % palette.count]
    }
}

// MARK: - Preview

#if DEBUG
struct GentleAvatar_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: GentleSpacing.md) {
            GentleAvatar(name: "Production Master", size: .small, isActive: true)
            GentleAvatar(name: "Dev Workspace", email: "dev@cloudflare.com", size: .medium, isActive: true)
            GentleAvatar(name: "Acme Corp", size: .large, isActive: false)
            GentleAvatar(name: "Cloudflare", size: .xlarge, isActive: true)
        }
        .padding()
        .background(GentleColor.background)
    }
}
#endif
