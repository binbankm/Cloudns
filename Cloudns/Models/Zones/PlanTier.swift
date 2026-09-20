import Foundation

// MARK: - PlanTier

/// Cloudflare subscription plan tiers and feature entitlement levels.
/// Supports natural Comparable ranking comparisons (e.g. `current >= .pro`).
public enum PlanTier: String, Codable, Comparable, CaseIterable, Sendable {
    case free
    case pro
    case business
    case enterprise
    case paid
    case addOn = "addon"

    // MARK: - Rank & Privilege Comparison

    public var rank: Int {
        switch self {
        case .free: 0
        case .paid: 1
        case .pro: 2
        case .business: 3
        case .enterprise: 4
        case .addOn: 99
        }
    }

    public static func < (lhs: PlanTier, rhs: PlanTier) -> Bool {
        lhs.rank < rhs.rank
    }

    // MARK: - Display Titles

    public var title: String {
        switch self {
        case .free: "FREE"
        case .pro: "PRO"
        case .business: "BUSINESS"
        case .enterprise: "ENTERPRISE"
        case .paid: "PAID"
        case .addOn: "ADD-ON"
        }
    }

    public var shortBadge: String {
        switch self {
        case .free: "FREE"
        case .pro: "PRO"
        case .business: "BIZ"
        case .enterprise: "ENT"
        case .paid: "PAID"
        case .addOn: "ADD-ON"
        }
    }

    public var displayName: String {
        switch self {
        case .free: "Free Plan"
        case .pro: "Pro Plan"
        case .business: "Business Plan"
        case .enterprise: "Enterprise Plan"
        case .paid: "Workers Paid"
        case .addOn: "Add-On Feature"
        }
    }
}
