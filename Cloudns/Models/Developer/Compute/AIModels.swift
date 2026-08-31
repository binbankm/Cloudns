import Foundation

// MARK: - AI Gateway Models

public struct AIGateway: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String?
    public let collectLogs: Bool?
    public let createdOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case collectLogs = "collect_logs"
        case createdOn = "created_on"
    }
    
    public init(id: String, name: String? = nil, collectLogs: Bool? = true, createdOn: String? = "2024-01-01T00:00:00Z") {
        self.id = id
        self.name = name
        self.collectLogs = collectLogs
        self.createdOn = createdOn
    }
    
}

// MARK: - Workers AI Models

public struct AIModel: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String?
    public let description: String?
    public let task: AIModelTask?
    
    public init(id: String, name: String?, description: String?, task: AIModelTask? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.task = task
    }
    
    public var modelPath: String {
        if let name = name, !name.isEmpty, name.contains("/") {
            return name
        }
        if id.contains("/") {
            return id
        }
        return name ?? id
    }
    
    public var shortName: String {
        let raw = modelPath
        return raw.split(separator: "/").last.map(String.init) ?? raw
    }
    
    public var taskName: String {
        task?.name ?? "General AI"
    }
}

public struct AIModelTask: Codable, Equatable, Sendable {
    public let id: String?
    public let name: String?
    public let description: String?
    
    public init(id: String?, name: String?, description: String?) {
        self.id = id
        self.name = name
        self.description = description
    }
}
