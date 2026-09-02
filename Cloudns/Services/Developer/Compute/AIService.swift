import Foundation

protocol AIServiceProtocol: Sendable {
    func getAIGateways(accountId: String) async throws -> [AIGateway]
    func listAIGateways(accountId: String) async throws -> [AIGateway]
    func createAIGateway(accountId: String, id: String) async throws
    func deleteAIGateway(accountId: String, id: String) async throws
    func getWorkersAIModels(accountId: String) async throws -> [AIModel]
    func listAIModels(accountId: String, search: String?) async throws -> [AIModel]
    func runAIChat(accountId: String, model: String, messages: [[String: String]]) async throws -> String
}

final class AIService: AIServiceProtocol {
    static let shared = AIService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getAIGateways(accountId: String) async throws -> [AIGateway] {
        try await listAIGateways(accountId: accountId)
    }
    
    func listAIGateways(accountId: String) async throws -> [AIGateway] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/ai-gateway/gateways")
        let (gateways, _): ([AIGateway]?, ResultInfo?) = try await client.performRequest(request)
        return gateways ?? []
    }
    
    func createAIGateway(accountId: String, id: String) async throws {
        let payload: [String: Any] = ["id": id, "collect_logs": true]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/ai-gateway/gateways", method: "POST", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deleteAIGateway(accountId: String, id: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/ai-gateway/gateways/\(id)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getWorkersAIModels(accountId: String) async throws -> [AIModel] {
        try await listAIModels(accountId: accountId)
    }
    
    func listAIModels(accountId: String, search: String? = nil) async throws -> [AIModel] {
        var queryItems: [URLQueryItem] = []
        if let s = search, !s.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: s))
        }
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/ai/models/search", queryItems: queryItems)
        let (models, _): ([AIModel]?, ResultInfo?) = try await client.performRequest(request)
        return models ?? []
    }
    
    func runAIChat(accountId: String, model: String, messages: [[String: String]]) async throws -> String {
        let payload: [String: Any] = ["messages": messages]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/ai/run/\(model)", method: "POST", body: data)
        struct AIRunResult: Codable {
            let response: String?
            let result: String?
            let output: String?
        }
        let (res, _): (AIRunResult?, ResultInfo?) = try await client.performRequest(request)
        return res?.response ?? res?.result ?? res?.output ?? "No response received"
    }
}
