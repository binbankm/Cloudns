import Foundation

// MARK: - AppTab Definition

public enum AppTab: Int, CaseIterable, Sendable {
    case dashboard = 0
    case domains = 1
    case developer = 2
    case devtools = 3
    case settings = 4
}
