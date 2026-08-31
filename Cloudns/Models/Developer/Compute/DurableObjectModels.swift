import Foundation

// MARK: - Durable Objects Models

public struct DurableObjectNamespace: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String?
    public let script: String?
    public let `class`: String?
    
    public var displayName: String {
        if let n = name, !n.isEmpty { return n }
        if let c = self.class, !c.isEmpty { return c }
        if let s = script, !s.isEmpty { return s }
        return id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, script, `class`
    }
    
    public init(id: String, name: String? = nil, script: String? = nil, class: String? = nil) {
        self.id = id
        self.name = name
        self.script = script
        self.class = `class`
    }
    
}

public struct DurableObjectInstance: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let hasStoredData: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case hasStoredData
    }
    
    public init(id: String, hasStoredData: Bool? = nil) {
        self.id = id
        self.hasStoredData = hasStoredData
    }
    
}
