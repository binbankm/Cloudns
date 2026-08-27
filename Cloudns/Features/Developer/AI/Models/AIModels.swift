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
    
    public static let placeholders: [AIGateway] = (0..<4).map { idx in
        AIGateway(id: "ai-gateway-\(idx + 1)")
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
    
    public static let placeholders: [AIModel] = [
        AIModel(id: "@cf/deepseek-ai/deepseek-r1-distill-qwen-32b", name: "@cf/deepseek-ai/deepseek-r1-distill-qwen-32b", description: "DeepSeek R1 reasoning model distilled into Qwen 32B.", task: AIModelTask(id: "text-generation", name: "Text Generation", description: nil)),
        AIModel(id: "@cf/meta/llama-3.3-70b-instruct-fp8-fast", name: "@cf/meta/llama-3.3-70b-instruct-fp8-fast", description: "Meta's flagship Llama 3.3 70B model with high-speed FP8 inference.", task: AIModelTask(id: "text-generation", name: "Text Generation", description: nil)),
        AIModel(id: "@cf/qwen/qwen2.5-72b-instruct", name: "@cf/qwen/qwen2.5-72b-instruct", description: "Alibaba's flagship open-weight 72B language model.", task: AIModelTask(id: "text-generation", name: "Text Generation", description: nil)),
        AIModel(id: "@cf/black-forest-labs/flux-1-schnell", name: "@cf/black-forest-labs/flux-1-schnell", description: "State-of-the-art 12B parameter text-to-image rectified flow transformer.", task: AIModelTask(id: "text-to-image", name: "Text-to-Image", description: nil)),
        AIModel(id: "@cf/openai/whisper-large-v3-turbo", name: "@cf/openai/whisper-large-v3-turbo", description: "High-accuracy multilingual speech-to-text recognition.", task: AIModelTask(id: "automatic-speech-recognition", name: "Speech Recognition", description: nil)),
        AIModel(id: "@cf/baai/bge-large-en-v1.5", name: "@cf/baai/bge-large-en-v1.5", description: "High-performance embedding model for semantic search and retrieval.", task: AIModelTask(id: "text-embeddings", name: "Text Embeddings", description: nil))
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
