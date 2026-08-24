import Foundation

struct Account: Codable, Identifiable, Sendable {
    let id: String
    let name: String
}
