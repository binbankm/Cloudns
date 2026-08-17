import Foundation

/// 统一的 Cloudflare Snippets 边缘代码片段领域服务
final class SnippetService {
    static let shared = SnippetService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    private let wafRulesService = WAFRulesService.shared
    
    private init() {}
    
    func getSnippets(zoneId: String) async throws -> [SnippetItem] {
        do {
            let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/snippets")
            let (snips, _): ([SnippetItem]?, ResultInfo?) = try await client.performRequest(request)
            return snips ?? []
        } catch {
            return []
        }
    }
    
    func getSnippetRuleset(zoneId: String) async throws -> (rulesetId: String?, rules: [WAFRule]) {
        let rs = try? await wafRulesService.fetchRulesetByPhase(zoneId: zoneId, phase: "http_request_snippet")
        return (rs?.id, rs?.rules ?? [])
    }
    
    func deleteSnippet(zoneId: String, snippetName: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/snippets/\(snippetName)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deleteSnippetRule(zoneId: String, rulesetId: String, ruleId: String) async throws {
        try await wafRulesService.deleteWAFRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId)
    }
    
    func getSnippetContent(zoneId: String, name: String) async throws -> String {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/snippets/\(name)/content", contentType: "")
        let data = try await client.performDataRequest(request)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func putSnippet(zoneId: String, name: String, code: String) async throws {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(name).js\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/javascript\r\n\r\n".data(using: .utf8)!)
        body.append(code.data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/snippets/\(name)",
            method: "PUT",
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
        struct Res: Codable { let snippet_name: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func bindSnippetRule(zoneId: String, snippetName: String, expression: String, description: String?) async throws {
        let rs = try? await wafRulesService.fetchRulesetByPhase(zoneId: zoneId, phase: "http_request_snippet")
        let param = ActionParameters(snippet: ActionParameters.SnippetRef(name: snippetName))
        if let existing = rs {
            _ = try await wafRulesService.createWAFRule(
                zoneId: zoneId,
                rulesetId: existing.id,
                action: "run_snippet",
                expression: expression,
                description: description ?? "Snippet \(snippetName)",
                enabled: true,
                ratelimit: nil,
                actionParameters: param
            )
        } else {
            _ = try await wafRulesService.createRuleset(
                zoneId: zoneId,
                phase: "http_request_snippet",
                action: "run_snippet",
                expression: expression,
                description: description ?? "Snippet \(snippetName)",
                enabled: true,
                ratelimit: nil,
                actionParameters: param
            )
        }
    }
}
