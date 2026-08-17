import Foundation

// MARK: - AI Gateway Models

public struct AIGateway: Codable, Identifiable, Equatable {
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
    
    public static let placeholders: [AIGateway] = (0..<4).map { idx in
        AIGateway(id: "ai-gateway-\(idx + 1)")
    }
}

// MARK: - Workers AI Models

public struct AIModel: Codable, Identifiable, Equatable {
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
    
    public static let placeholders: [AIModel] = [
        AIModel(id: "@cf/meta/llama-3-8b-instruct", name: "@cf/meta/llama-3-8b-instruct", description: "Generation 3 of Llama, trained on 8B tokens.", task: AIModelTask(id: "text-generation", name: "Text Generation", description: nil)),
        AIModel(id: "@cf/stabilityai/stable-diffusion-xl-base-1.0", name: "@cf/stabilityai/stable-diffusion-xl-base-1.0", description: "Diffusion-based text-to-image generative model.", task: AIModelTask(id: "text-to-image", name: "Text-to-Image", description: nil)),
        AIModel(id: "@cf/baai/bge-large-en-v1.5", name: "@cf/baai/bge-large-en-v1.5", description: "Embedding model for text similarity and search.", task: AIModelTask(id: "text-embeddings", name: "Text Embeddings", description: nil))
    ]
    
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

public struct AIModelTask: Codable, Equatable {
    public let id: String?
    public let name: String?
    public let description: String?
    
    public init(id: String?, name: String?, description: String?) {
        self.id = id
        self.name = name
        self.description = description
    }
}
