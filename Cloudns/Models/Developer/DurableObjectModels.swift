import Foundation

// MARK: - Durable Objects Models

public struct DurableObjectNamespace: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let script: String?
    public let `class`: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, script, `class`
    }
    
    public init(id: String, name: String, script: String? = nil, class: String? = nil) {
        self.id = id
        self.name = name
        self.script = script
        self.class = `class`
    }
    
    public static let placeholders: [DurableObjectNamespace] = [
        DurableObjectNamespace(id: "do_1", name: "UserSessionCoordinator", script: "auth-worker", class: "SessionCoordinator"),
        DurableObjectNamespace(id: "do_2", name: "RoomPresenceManager", script: "chat-worker", class: "RoomPresence")
    ]
}

public struct DurableObjectInstance: Codable, Identifiable, Equatable {
    public let id: String
    public let hasStoredData: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case hasStoredData = "hasStoredData"
    }
    
    public init(id: String, hasStoredData: Bool? = nil) {
        self.id = id
        self.hasStoredData = hasStoredData
    }
}
