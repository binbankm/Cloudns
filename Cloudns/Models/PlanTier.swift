import Foundation

// MARK: - Plan Tier Enum

public enum PlanTier: String, Codable, Sendable {
    case free = "free"
    case pro = "pro"
    case business = "business"
    case enterprise = "enterprise"
    case paid = "paid"
    case addOn = "addon"
    
    public var title: String {
        switch self {
        case .free: return "FREE"
        case .pro: return "PRO"
        case .business: return "BUSINESS"
        case .enterprise: return "ENTERPRISE"
        case .paid: return "PAID"
        case .addOn: return "ADD-ON"
        }
    }
}
