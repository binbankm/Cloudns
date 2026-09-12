import Foundation

// MARK: - Plan Tier Enum

public enum PlanTier: String, Codable, Sendable {
    case free
    case pro
    case business
    case enterprise
    case paid
    case addOn = "addon"

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
}
