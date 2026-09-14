import SwiftUI

// MARK: - Gentle Typography Tokens (Apple HIG & SF Pro Rounded)

/// Unified typography system enforcing SF Pro Rounded and Apple HIG Dynamic Type scales.
public enum GentleTypography {
    /// Hero large header (32pt rounded bold)
    public static var hero: Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }

    /// Page navigation large title (26pt rounded bold)
    public static var titleLarge: Font {
        .system(.title, design: .rounded).weight(.bold)
    }

    /// Section group title (20pt rounded semibold)
    public static var titleSection: Font {
        .system(.title2, design: .rounded).weight(.semibold)
    }

    /// Card primary title / headline (17pt rounded semibold)
    public static var cardTitle: Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }

    /// Standard body text (16pt rounded regular)
    public static var body: Font {
        .system(.body, design: .rounded)
    }

    /// Body medium emphasis (16pt rounded medium)
    public static var bodyMedium: Font {
        .system(.body, design: .rounded).weight(.medium)
    }

    /// Subheadline text (15pt rounded regular)
    public static var subheadline: Font {
        .system(.subheadline, design: .rounded)
    }

    /// Subheadline medium emphasis (15pt rounded medium)
    public static var subheadlineMedium: Font {
        .system(.subheadline, design: .rounded).weight(.medium)
    }

    /// Subheadline semibold emphasis (15pt rounded semibold)
    public static var subheadlineSemibold: Font {
        .system(.subheadline, design: .rounded).weight(.semibold)
    }

    /// Callout text (14pt rounded regular)
    public static var callout: Font {
        .system(.callout, design: .rounded)
    }

    /// Footnote text (13pt rounded regular)
    public static var footnote: Font {
        .system(.footnote, design: .rounded)
    }

    /// Caption text (12pt rounded regular)
    public static var caption: Font {
        .system(.caption, design: .rounded)
    }

    /// Caption small / secondary (11pt rounded semibold)
    public static var captionSmall: Font {
        .system(.caption2, design: .rounded).weight(.semibold)
    }

    /// Standard HIG Hierarchy Aliases
    public static var largeTitle: Font { hero }
    public static var title: Font { titleLarge }
    public static var title2: Font { titleSection }
    public static var headline: Font { cardTitle }
    public static var caption2: Font { captionSmall }

    /// Button action label (17pt rounded semibold)
    public static var buttonLabel: Font {
        .system(.body, design: .rounded).weight(.semibold)
    }

    // MARK: - Monospaced Numbers & Metrics (AGENTS.md 强制要求)

    /// Large monospaced metric number (for Analytics/Health hero counts)
    public static var metricHero: Font {
        .system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit()
    }

    /// Standard monospaced metric number (for section summaries)
    public static var metricMedium: Font {
        .system(.title2, design: .rounded).weight(.semibold).monospacedDigit()
    }

    /// Card value monospaced number (for card counters, DNS counts)
    public static var metricCard: Font {
        .system(.headline, design: .rounded).weight(.semibold).monospacedDigit()
    }

    /// Compact monospaced metric number (e.g. TTL value, response ms)
    public static var metricSmall: Font {
        .system(.subheadline, design: .rounded).weight(.medium).monospacedDigit()
    }

    /// DNS record content, IP address, TTL (code font with monospaced digits)
    public static var codeValue: Font {
        .system(.subheadline, design: .monospaced)
    }

    /// Timestamp and relative date string
    public static var timestamp: Font {
        .system(.caption, design: .rounded).monospacedDigit()
    }
}
