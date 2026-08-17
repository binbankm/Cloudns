import Foundation

/// 统一的 Cloudflare 动态 URL 重定向规则领域服务
final class RedirectRulesService {
    static let shared = RedirectRulesService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    private let wafRulesService = WAFRulesService.shared
    
    private init() {}
    
    func getRedirectRules(zoneId: String) async throws -> [RedirectRuleItem] {
        do {
            let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/rulesets/phases/http_request_dynamic_redirect/entrypoint")
            let (ruleset, _): (Ruleset?, ResultInfo?) = try await client.performRequest(request)
            guard let rules = ruleset?.rules else { return [] }
            return rules.compactMap { (r: WAFRule) -> RedirectRuleItem? in
                guard let ap = r.action_parameters else { return nil }
                return RedirectRuleItem(
                    id: r.id,
                    description: r.description,
                    expression: r.expression,
                    targetUrl: ap.from_value?.target_url?.value ?? ap.from_value?.target_url?.expression,
                    statusCode: ap.from_value?.status_code ?? 301,
                    preserveQueryString: ap.from_value?.preserve_query_string,
                    enabled: r.enabled
                )
            }
        } catch {
            return []
        }
    }
    
    func createRedirectRule(
        zoneId: String,
        description: String,
        expression: String,
        targetUrl: String,
        statusCode: Int,
        preserveQueryString: Bool = false
    ) async throws {
        let rs = try? await wafRulesService.fetchRulesetByPhase(zoneId: zoneId, phase: "http_request_dynamic_redirect")
        let actionParam = ActionParameters(
            from_value: ActionParameters.FromValue(
                status_code: statusCode,
                target_url: ActionParameters.TargetUrl(value: targetUrl, expression: nil),
                preserve_query_string: preserveQueryString
            )
        )
        if let ruleset = rs {
            _ = try await wafRulesService.createWAFRule(
                zoneId: zoneId,
                rulesetId: ruleset.id,
                action: "redirect",
                expression: expression,
                description: description,
                enabled: true,
                ratelimit: nil,
                actionParameters: actionParam
            )
        } else {
            _ = try await wafRulesService.createRuleset(
                zoneId: zoneId,
                phase: "http_request_dynamic_redirect",
                action: "redirect",
                expression: expression,
                description: description,
                enabled: true,
                ratelimit: nil,
                actionParameters: actionParam
            )
        }
    }
    
    func deleteRedirectRule(zoneId: String, ruleId: String) async throws {
        guard let rs = try await wafRulesService.fetchRulesetByPhase(zoneId: zoneId, phase: "http_request_dynamic_redirect") else { return }
        try await wafRulesService.deleteWAFRule(zoneId: zoneId, rulesetId: rs.id, ruleId: ruleId)
    }
}
