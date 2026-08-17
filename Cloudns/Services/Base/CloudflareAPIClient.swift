import Foundation

/// Centralized API Client Facade providing backwards compatibility while delegating
/// domain-specific operations to modular Domain Services.
class CloudflareAPIClient {
    static let shared = CloudflareAPIClient()
    
    let serviceName = "com.cloudflare.api"
    private let baseURL = "https://api.cloudflare.com/client/v4"
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    // Domain Services
    private let zoneService = ZoneService.shared
    private let dnsService = DNSService.shared
    private let securityService = SecuritySettingsService.shared
    private let certificateService = CertificateService.shared
    private let speedService = SpeedAndNetworkService.shared
    
    // Developer Services
    private let workerService = WorkerService.shared
    private let pagesService = PagesService.shared
    private let aiService = AIService.shared
    private let queueService = QueueService.shared
    private let kvService = KVService.shared
    private let r2Service = R2Service.shared
    private let d1Service = D1Service.shared
    private let doService = DurableObjectService.shared
    private let hyperdriveService = HyperdriveService.shared
    private let tunnelService = TunnelService.shared
    private let turnstileService = TurnstileService.shared
    private let accessService = AccessService.shared
    private let gatewayService = GatewayService.shared
    private let alertingService = AlertingService.shared
    private let bulkRedirectService = BulkRedirectService.shared
    
    // Rules & Analytics Services
    private let wafRulesService = WAFRulesService.shared
    private let redirectRulesService = RedirectRulesService.shared
    private let snippetService = SnippetService.shared
    private let emailRoutingService = EmailRoutingService.shared
    private let loadBalancerService = LoadBalancerService.shared
    private let analyticsService = AnalyticsService.shared
    private let devToolsService = DevToolsService.shared
    
    private init() {}
    
    // MARK: - Core Networking Forwarders
    
    func createAuthenticatedRequest(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: String = "GET",
        body: Data? = nil,
        contentType: String = "application/json"
    ) throws -> URLRequest {
        try factory.createAuthenticatedRequest(
            path: path,
            queryItems: queryItems,
            method: method,
            body: body,
            contentType: contentType
        )
    }
    
    func performRequest<T: Codable>(_ request: URLRequest) async throws -> (T?, ResultInfo?) {
        try await client.performRequest(request)
    }
    
    // MARK: - Zones & Accounts
    
    func getZones(page: Int = 1, perPage: Int = 50) async throws -> ([Zone], ResultInfo?) {
        try await zoneService.getZones(page: page, perPage: perPage)
    }
    
    func getAccounts() async throws -> [Account] {
        try await zoneService.getAccounts()
    }
    
    func getZoneDetails(zoneId: String) async throws -> Zone {
        try await zoneService.getZoneDetails(zoneId: zoneId)
    }
    
    func createZone(name: String, accountId: String) async throws -> Zone {
        try await zoneService.createZone(name: name, accountId: accountId)
    }
    
    func deleteZone(zoneId: String) async throws {
        _ = try await zoneService.deleteZone(zoneId: zoneId)
    }
    
    func updateZoneStatus(zoneId: String, paused: Bool) async throws {
        try await zoneService.updateZoneStatus(zoneId: zoneId, paused: paused)
    }
    
    func fetchZoneSettings(zoneId: String) async throws -> [ZoneSetting] {
        try await securityService.fetchZoneSettings(zoneId: zoneId)
    }
    
    func updateZoneSetting(zoneId: String, settingId: String, value: SettingValue) async throws {
        _ = try await securityService.updateSecuritySetting(zoneId: zoneId, settingName: settingId, value: value.rawAnyValue)
    }
    
    // MARK: - DNS & DNSSEC
    
    func getDNSRecords(zoneId: String, page: Int = 1, perPage: Int = 50, search: String? = nil, order: String = "name", direction: String = "asc") async throws -> ([DNSRecord], ResultInfo?) {
        try await dnsService.getDNSRecords(zoneId: zoneId, page: page, perPage: perPage, search: search, order: order, direction: direction)
    }
    
    func createDNSRecord(zoneId: String, payload: DNSRecordPayload) async throws -> DNSRecord {
        try await dnsService.createDNSRecord(zoneId: zoneId, payload: payload)
    }
    
    func updateDNSRecord(zoneId: String, recordId: String, payload: DNSRecordPayload) async throws -> DNSRecord {
        try await dnsService.updateDNSRecord(zoneId: zoneId, recordId: recordId, payload: payload)
    }
    
    func deleteDNSRecord(zoneId: String, recordId: String) async throws {
        _ = try await dnsService.deleteDNSRecord(zoneId: zoneId, recordId: recordId)
    }
    
    func batchDNSRecords(zoneId: String, deletes: [String]) async throws {
        try await dnsService.batchDNSRecords(zoneId: zoneId, deletes: deletes)
    }
    
    func exportDNSRecords(zoneId: String) async throws -> URL {
        try await dnsService.exportDNSRecords(zoneId: zoneId)
    }
    
    func importDNSRecords(zoneId: String, fileURL: URL) async throws {
        try await dnsService.importDNSRecords(zoneId: zoneId, fileURL: fileURL)
    }
    
    func getDNSSEC(zoneId: String) async throws -> DNSSEC {
        try await dnsService.getDNSSEC(zoneId: zoneId)
    }
    
    func updateDNSSEC(zoneId: String, status: String) async throws {
        _ = try await dnsService.updateDNSSEC(zoneId: zoneId, status: status)
    }
    
    // MARK: - Security & WAF
    
    func getWAFRules(zoneId: String) async throws -> [WAFRule] {
        try await securityService.getWAFRules(zoneId: zoneId)
    }
    
    func updateWAFRules(zoneId: String, rules: [WAFRule]) async throws -> [WAFRule] {
        try await securityService.updateWAFRules(zoneId: zoneId, rules: rules)
    }
    
    func fetchIPAccessRules(zoneId: String) async throws -> [IPAccessRule] {
        let (rules, _) = try await securityService.getIPAccessRules(zoneId: zoneId)
        return rules
    }
    
    func createIPAccessRule(zoneId: String, mode: String, target: String, value: String, notes: String?) async throws -> IPAccessRule {
        try await securityService.createIPAccessRule(zoneId: zoneId, mode: mode, target: target, value: value, notes: notes)
    }
    
    func createIPAccessRule(zoneId: String, mode: String, target: String, value: String, notes: String) async throws -> IPAccessRule {
        try await securityService.createIPAccessRule(zoneId: zoneId, mode: mode, target: target, value: value, notes: notes)
    }
    
    func deleteIPAccessRule(zoneId: String, ruleId: String) async throws {
        try await securityService.deleteIPAccessRule(zoneId: zoneId, ruleId: ruleId)
    }
    
    func fetchSecurityEvents(zoneId: String, limit: Int = 30) async throws -> [SecurityEvent] {
        try await securityService.fetchSecurityEvents(zoneId: zoneId, limit: limit)
    }
    
    // MARK: - SSL & Certificates
    
    func fetchCertificatePacks(zoneId: String) async throws -> [CertificatePack] {
        try await certificateService.getCertificates(zoneId: zoneId)
    }
    
    func fetchCustomCertificates(zoneId: String) async throws -> [CustomCertificate] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/custom_certificates")
        let (certs, _): ([CustomCertificate]?, ResultInfo?) = try await client.performRequest(request)
        return certs ?? []
    }
    
    func deleteCertificatePack(zoneId: String, packId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/ssl/certificate_packs/\(packId)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deleteCustomCertificate(zoneId: String, certificateId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/custom_certificates/\(certificateId)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func uploadCustomCertificate(zoneId: String, certificate: String, privateKey: String) async throws {
        let payload: [String: Any] = ["certificate": certificate, "private_key": privateKey]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/custom_certificates", method: "POST", body: data)
        struct UploadRes: Codable { let id: String? }
        let (_, _): (UploadRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getUniversalSSLSettings(zoneId: String) async throws -> Bool {
        try await certificateService.getUniversalSSLSetting(zoneId: zoneId)
    }
    
    func updateUniversalSSLSettings(zoneId: String, enabled: Bool) async throws {
        try await certificateService.updateUniversalSSL(zoneId: zoneId, enabled: enabled)
    }
    
    // MARK: - Speed, Caching & Network
    
    func purgeCacheEverything(zoneId: String) async throws {
        try await speedService.purgeEverything(zoneId: zoneId)
    }
    
    func purgeCacheByURLs(zoneId: String, urls: [String]) async throws {
        try await speedService.purgeFiles(zoneId: zoneId, files: urls)
    }
    
    func purgeCacheByHosts(zoneId: String, hosts: [String]) async throws {
        try await speedService.purgeCacheByHosts(zoneId: zoneId, hosts: hosts)
    }
    
    func purgeCacheByPrefixes(zoneId: String, prefixes: [String]) async throws {
        try await speedService.purgeCacheByPrefixes(zoneId: zoneId, prefixes: prefixes)
    }
    
    func purgeCacheByTags(zoneId: String, tags: [String]) async throws {
        try await speedService.purgeCacheByTags(zoneId: zoneId, tags: tags)
    }
    
    // MARK: - Rulesets & Rules
    
    func fetchRulesetByPhase(zoneId: String, phase: String) async throws -> Ruleset? {
        try await wafRulesService.fetchRulesetByPhase(zoneId: zoneId, phase: phase)
    }
    
    func getPageRules(zoneId: String) async throws -> [PageRule] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/pagerules")
        let (rules, _): ([PageRule]?, ResultInfo?) = try await client.performRequest(request)
        return rules ?? []
    }
    
    func updatePageRuleStatus(zoneId: String, ruleId: String, status: String) async throws {
        let payload: [String: Any] = ["status": status]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/pagerules/\(ruleId)", method: "PATCH", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deletePageRule(zoneId: String, ruleId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/pagerules/\(ruleId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func updateWAFRule(
        zoneId: String,
        rulesetId: String,
        ruleId: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig? = nil,
        actionParameters: ActionParameters? = nil
    ) async throws {
        try await wafRulesService.updateWAFRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId, action: action, expression: expression, description: description, enabled: enabled, ratelimit: ratelimit, actionParameters: actionParameters)
    }
    
    func deleteWAFRule(zoneId: String, rulesetId: String, ruleId: String) async throws {
        try await wafRulesService.deleteWAFRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId)
    }
    
    func createWAFRule(
        zoneId: String,
        rulesetId: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig? = nil,
        actionParameters: ActionParameters? = nil
    ) async throws -> Ruleset {
        try await wafRulesService.createWAFRule(zoneId: zoneId, rulesetId: rulesetId, action: action, expression: expression, description: description, enabled: enabled, ratelimit: ratelimit, actionParameters: actionParameters)
    }
    
    func createRuleset(
        zoneId: String,
        phase: String,
        action: String,
        expression: String,
        description: String?,
        enabled: Bool,
        ratelimit: RateLimitConfig? = nil,
        actionParameters: ActionParameters? = nil
    ) async throws -> Ruleset {
        try await wafRulesService.createRuleset(zoneId: zoneId, phase: phase, action: action, expression: expression, description: description, enabled: enabled, ratelimit: ratelimit, actionParameters: actionParameters)
    }
    
    func getRedirectRules(zoneId: String) async throws -> [RedirectRuleItem] {
        try await redirectRulesService.getRedirectRules(zoneId: zoneId)
    }
    
    func createRedirectRule(
        zoneId: String,
        description: String,
        expression: String,
        targetUrl: String,
        statusCode: Int,
        preserveQueryString: Bool = false
    ) async throws {
        try await redirectRulesService.createRedirectRule(zoneId: zoneId, description: description, expression: expression, targetUrl: targetUrl, statusCode: statusCode, preserveQueryString: preserveQueryString)
    }
    
    func deleteRedirectRule(zoneId: String, ruleId: String) async throws {
        try await redirectRulesService.deleteRedirectRule(zoneId: zoneId, ruleId: ruleId)
    }
    
    func getSnippets(zoneId: String) async throws -> [SnippetItem] {
        try await snippetService.getSnippets(zoneId: zoneId)
    }
    
    func getSnippetRuleset(zoneId: String) async throws -> (rulesetId: String?, rules: [WAFRule]) {
        try await snippetService.getSnippetRuleset(zoneId: zoneId)
    }
    
    func deleteSnippet(zoneId: String, snippetName: String) async throws {
        try await snippetService.deleteSnippet(zoneId: zoneId, snippetName: snippetName)
    }
    
    func deleteSnippetRule(zoneId: String, rulesetId: String, ruleId: String) async throws {
        try await snippetService.deleteSnippetRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId)
    }
    
    func getSnippetContent(zoneId: String, name: String) async throws -> String {
        try await snippetService.getSnippetContent(zoneId: zoneId, name: name)
    }
    
    func putSnippet(zoneId: String, name: String, code: String) async throws {
        try await snippetService.putSnippet(zoneId: zoneId, name: name, code: code)
    }
    
    func bindSnippetRule(zoneId: String, snippetName: String, expression: String, description: String?) async throws {
        try await snippetService.bindSnippetRule(zoneId: zoneId, snippetName: snippetName, expression: expression, description: description)
    }
    
    // MARK: - Email Routing & Load Balancing
    
    func getEmailRoutingSettings(zoneId: String) async throws -> EmailRoutingSettings? {
        try await emailRoutingService.getEmailRoutingSettings(zoneId: zoneId)
    }
    
    func getEmailRoutingRules(zoneId: String) async throws -> [EmailRoutingRule] {
        try await emailRoutingService.getEmailRoutingRules(zoneId: zoneId)
    }
    
    func getEmailDestinations(accountId: String) async throws -> [EmailDestinationAddress] {
        try await emailRoutingService.getEmailDestinations(accountId: accountId)
    }
    
    func createEmailRoutingRule(zoneId: String, rule: EmailRoutingRuleInput) async throws -> EmailRoutingRule {
        try await emailRoutingService.createEmailRoutingRule(zoneId: zoneId, rule: rule)
    }
    
    func deleteEmailRoutingRule(zoneId: String, ruleId: String) async throws {
        try await emailRoutingService.deleteEmailRoutingRule(zoneId: zoneId, ruleId: ruleId)
    }
    
    func getLoadBalancers(zoneId: String) async throws -> [LoadBalancer] {
        try await loadBalancerService.getLoadBalancers(zoneId: zoneId)
    }
    
    func getLBPools(accountId: String) async throws -> [LBPool] {
        try await loadBalancerService.getLBPools(accountId: accountId)
    }
    
    func getLBMonitors(accountId: String) async throws -> [LBMonitor] {
        try await loadBalancerService.getLBMonitors(accountId: accountId)
    }
    
    func createLoadBalancer(zoneId: String, lb: LoadBalancerInput) async throws -> LoadBalancer {
        try await loadBalancerService.createLoadBalancer(zoneId: zoneId, lb: lb)
    }
    
    func createLoadBalancer(zoneId: String, payload: LoadBalancerInput) async throws -> LoadBalancer {
        try await loadBalancerService.createLoadBalancer(zoneId: zoneId, lb: payload)
    }
    
    func deleteLoadBalancer(zoneId: String, lbId: String) async throws {
        try await loadBalancerService.deleteLoadBalancer(zoneId: zoneId, lbId: lbId)
    }
    
    func createLBPool(accountId: String, pool: LBPoolUpdate) async throws -> LBPool {
        try await loadBalancerService.createLBPool(accountId: accountId, pool: pool)
    }
    
    func deleteLBPool(accountId: String, poolId: String) async throws {
        try await loadBalancerService.deleteLBPool(accountId: accountId, poolId: poolId)
    }
    
    func createLBMonitor(accountId: String, monitor: LBMonitorUpdate) async throws -> LBMonitor {
        try await loadBalancerService.createLBMonitor(accountId: accountId, monitor: monitor)
    }
    
    func deleteLBMonitor(accountId: String, monitorId: String) async throws {
        try await loadBalancerService.deleteLBMonitor(accountId: accountId, monitorId: monitorId)
    }
    
    // MARK: - Developer Workers & Pages
    
    func getWorkers(accountId: String) async throws -> [WorkerScript] {
        try await workerService.getWorkers(accountId: accountId)
    }
    
    func getWorkerScriptContent(accountId: String, scriptName: String) async throws -> WorkerScriptContentResult {
        try await workerService.getWorkerContent(accountId: accountId, scriptName: scriptName)
    }
    
    func createWorkerScript(accountId: String, name: String, code: String, isModule: Bool = false) async throws {
        try await workerService.uploadWorkerScript(accountId: accountId, scriptName: name, code: code)
    }
    
    func deleteWorkerScript(accountId: String, scriptName: String) async throws {
        try await workerService.deleteWorkerScript(accountId: accountId, scriptName: scriptName)
    }
    
    func getPagesProjects(accountId: String) async throws -> [PagesProject] {
        try await pagesService.getPagesProjects(accountId: accountId)
    }
    
    func createPagesProject(accountId: String, name: String, productionBranch: String = "main") async throws -> PagesProject {
        try await pagesService.createPagesProject(accountId: accountId, name: name, productionBranch: productionBranch)
    }
    
    func deletePagesProject(accountId: String, projectName: String) async throws {
        try await pagesService.deletePagesProject(accountId: accountId, projectName: projectName)
    }
    
    func updatePagesProject(
        accountId: String,
        projectName: String,
        buildCommand: String? = nil,
        destinationDir: String? = nil,
        rootDir: String? = nil,
        productionBranch: String? = nil,
        buildConfig: PagesBuildConfig? = nil,
        envConfig: PagesEnvConfig? = nil
    ) async throws {
        try await pagesService.updatePagesProject(accountId: accountId, projectName: projectName, buildCommand: buildCommand, destinationDir: destinationDir, rootDir: rootDir, productionBranch: productionBranch, buildConfig: buildConfig, envConfig: envConfig)
    }
    
    func getPagesDeployments(accountId: String, projectName: String) async throws -> [PagesDeployment] {
        try await pagesService.getPagesDeployments(accountId: accountId, projectName: projectName)
    }
    
    func getPagesDomains(accountId: String, projectName: String) async throws -> [PagesDomain] {
        try await pagesService.getPagesDomains(accountId: accountId, projectName: projectName)
    }
    
    func addPagesDomain(accountId: String, projectName: String, domain: String) async throws {
        try await pagesService.addPagesDomain(accountId: accountId, projectName: projectName, domain: domain)
    }
    
    func deletePagesDomain(accountId: String, projectName: String, domain: String) async throws {
        try await pagesService.deletePagesDomain(accountId: accountId, projectName: projectName, domain: domain)
    }
    
    func rollbackPagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws {
        try await pagesService.rollbackPagesDeployment(accountId: accountId, projectName: projectName, deploymentId: deploymentId)
    }
    
    func retryPagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws {
        try await pagesService.retryPagesDeployment(accountId: accountId, projectName: projectName, deploymentId: deploymentId)
    }
    
    func deletePagesDeployment(accountId: String, projectName: String, deploymentId: String) async throws {
        try await pagesService.deletePagesDeployment(accountId: accountId, projectName: projectName, deploymentId: deploymentId)
    }
    
    func getPagesDeploymentLogs(accountId: String, projectName: String, deploymentId: String) async throws -> [PagesDeploymentLog] {
        try await pagesService.getPagesDeploymentLogs(accountId: accountId, projectName: projectName, deploymentId: deploymentId)
    }
    
    func getWorkerBindings(accountId: String, scriptName: String) async throws -> [WorkerBinding] {
        try await workerService.getWorkerBindings(accountId: accountId, scriptName: scriptName)
    }
    
    func patchWorkerBindings(accountId: String, scriptName: String, bindings: [WorkerBinding]) async throws {
        try await workerService.patchWorkerBindings(accountId: accountId, scriptName: scriptName, bindings: bindings)
    }
    
    func getWorkerSubdomain(accountId: String, scriptName: String) async throws -> WorkerSubdomain? {
        try await workerService.getWorkerSubdomain(accountId: accountId, scriptName: scriptName)
    }
    
    func setWorkerSubdomain(accountId: String, scriptName: String, enabled: Bool) async throws {
        try await workerService.setWorkerSubdomain(accountId: accountId, scriptName: scriptName, enabled: enabled)
    }
    
    func getWorkerSchedules(accountId: String, scriptName: String) async throws -> [WorkerSchedule] {
        try await workerService.getWorkerSchedules(accountId: accountId, scriptName: scriptName)
    }
    
    func putWorkerSchedules(accountId: String, scriptName: String, crons: [String]) async throws {
        try await workerService.putWorkerSchedules(accountId: accountId, scriptName: scriptName, crons: crons)
    }
    
    func getWorkerSecrets(accountId: String, scriptName: String) async throws -> [WorkerSecret] {
        try await workerService.getWorkerSecrets(accountId: accountId, scriptName: scriptName)
    }
    
    func putWorkerSecret(accountId: String, scriptName: String, name: String, text: String) async throws {
        try await workerService.putWorkerSecret(accountId: accountId, scriptName: scriptName, name: name, text: text)
    }
    
    func deleteWorkerSecret(accountId: String, scriptName: String, name: String) async throws {
        try await workerService.deleteWorkerSecret(accountId: accountId, scriptName: scriptName, name: name)
    }
    
    func getWorkerCustomDomains(accountId: String, scriptName: String) async throws -> [WorkerCustomDomain] {
        try await workerService.getWorkerCustomDomains(accountId: accountId, scriptName: scriptName)
    }
    
    func attachWorkerDomain(accountId: String, scriptName: String, hostname: String, zoneId: String) async throws {
        try await workerService.attachWorkerDomain(accountId: accountId, scriptName: scriptName, hostname: hostname, zoneId: zoneId)
    }
    
    func attachWorkerDomain(accountId: String, hostname: String, zoneId: String, service: String) async throws {
        try await attachWorkerDomain(accountId: accountId, scriptName: service, hostname: hostname, zoneId: zoneId)
    }
    
    func detachWorkerDomain(accountId: String, domainId: String) async throws {
        try await workerService.detachWorkerDomain(accountId: accountId, domainId: domainId)
    }
    
    func createWorkerTailSession(accountId: String, scriptName: String) async throws -> WorkerTailSession {
        try await workerService.createWorkerTailSession(accountId: accountId, scriptName: scriptName)
    }
    
    func deleteWorkerTailSession(accountId: String, scriptName: String, tailId: String) async throws {
        try await workerService.deleteWorkerTailSession(accountId: accountId, scriptName: scriptName, tailId: tailId)
    }
    
    func getWorkerAnalytics(accountId: String, scriptName: String, days: Int = 1) async throws -> [WorkerAnalyticsItem] {
        try await analyticsService.getWorkerAnalytics(accountId: accountId, scriptName: scriptName, days: days)
    }
    
    func testWorkerDispatch(urlString: String, httpMethod: String, headers: [String: String], body: String?) async throws -> HTTPInspectionResult {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        if let b = body, !b.isEmpty { request.httpBody = b.data(using: .utf8) }
        let startTime = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await URLSession.shared.data(for: request)
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        var headerItems: [HTTPHeaderItem] = []
        for (k, v) in httpResponse.allHeaderFields { headerItems.append(HTTPHeaderItem(key: "\(k)", value: "\(v)")) }
        let bodyString = String(data: data, encoding: .utf8)
        return HTTPInspectionResult(
            url: urlString,
            statusCode: httpResponse.statusCode,
            statusText: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
            headers: headerItems,
            cfRay: httpResponse.value(forHTTPHeaderField: "cf-ray"),
            cfCacheStatus: httpResponse.value(forHTTPHeaderField: "cf-cache-status"),
            server: httpResponse.value(forHTTPHeaderField: "server"),
            durationMs: duration,
            responseBody: bodyString
        )
    }
    
    // MARK: - Storage (KV, R2, D1, Hyperdrive, Durable Objects)
    
    func getR2Buckets(accountId: String) async throws -> [R2Bucket] {
        try await r2Service.getR2Buckets(accountId: accountId)
    }
    
    func createR2Bucket(accountId: String, name: String, locationHint: String? = nil) async throws -> R2Bucket {
        try await r2Service.createR2Bucket(accountId: accountId, name: name, locationHint: locationHint)
    }
    
    func deleteR2Bucket(accountId: String, bucketName: String) async throws {
        try await r2Service.deleteR2Bucket(accountId: accountId, bucketName: bucketName)
    }
    
    func getR2Objects(accountId: String, bucketName: String) async throws -> [R2Object] {
        try await r2Service.getR2Objects(accountId: accountId, bucketName: bucketName)
    }
    
    func putR2Object(accountId: String, bucketName: String, objectKey: String, data: Data, contentType: String = "application/octet-stream") async throws {
        try await r2Service.putR2Object(accountId: accountId, bucketName: bucketName, objectKey: objectKey, data: data, contentType: contentType)
    }
    
    func deleteR2Object(accountId: String, bucketName: String, objectKey: String) async throws {
        try await r2Service.deleteR2Object(accountId: accountId, bucketName: bucketName, objectKey: objectKey)
    }
    
    func getR2ManagedDomain(accountId: String, bucketName: String) async throws -> R2ManagedDomain {
        try await r2Service.getR2ManagedDomain(accountId: accountId, bucketName: bucketName)
    }
    
    func setR2ManagedDomain(accountId: String, bucketName: String, enabled: Bool) async throws {
        try await r2Service.setR2ManagedDomain(accountId: accountId, bucketName: bucketName, enabled: enabled)
    }
    
    func getR2CustomDomains(accountId: String, bucketName: String) async throws -> [R2CustomDomain] {
        try await r2Service.getR2CustomDomains(accountId: accountId, bucketName: bucketName)
    }
    
    func deleteR2CustomDomain(accountId: String, bucketName: String, domain: String) async throws {
        try await r2Service.deleteR2CustomDomain(accountId: accountId, bucketName: bucketName, domain: domain)
    }
    
    func getR2CORS(accountId: String, bucketName: String) async throws -> [R2CORSRule] {
        try await r2Service.getR2CORS(accountId: accountId, bucketName: bucketName)
    }
    
    func putR2CORS(accountId: String, bucketName: String, rules: [R2CORSRule]) async throws {
        try await r2Service.putR2CORS(accountId: accountId, bucketName: bucketName, rules: rules)
    }
    
    func deleteR2CORS(accountId: String, bucketName: String) async throws {
        try await r2Service.deleteR2CORS(accountId: accountId, bucketName: bucketName)
    }
    
    func getKVNamespaces(accountId: String) async throws -> [KVNamespace] {
        try await kvService.getKVNamespaces(accountId: accountId)
    }
    
    func createKVNamespace(accountId: String, title: String) async throws -> KVNamespace {
        try await kvService.createKVNamespace(accountId: accountId, title: title)
    }
    
    func deleteKVNamespace(accountId: String, namespaceId: String) async throws {
        try await kvService.deleteKVNamespace(accountId: accountId, namespaceId: namespaceId)
    }
    
    func getKVKeys(accountId: String, namespaceId: String) async throws -> [KVKey] {
        try await kvService.getKVKeys(accountId: accountId, namespaceId: namespaceId)
    }
    
    func getKVValue(accountId: String, namespaceId: String, key: String) async throws -> String {
        try await kvService.getKVValue(accountId: accountId, namespaceId: namespaceId, key: key)
    }
    
    func saveKVValue(accountId: String, namespaceId: String, key: String, value: String, expirationTTL: Int? = nil) async throws {
        try await kvService.saveKVValue(accountId: accountId, namespaceId: namespaceId, key: key, value: value, expirationTTL: expirationTTL)
    }
    
    func deleteKVKey(accountId: String, namespaceId: String, key: String) async throws {
        try await kvService.deleteKVKey(accountId: accountId, namespaceId: namespaceId, key: key)
    }
    
    func getD1Databases(accountId: String) async throws -> [D1Database] {
        try await d1Service.getD1Databases(accountId: accountId)
    }
    
    func createD1Database(accountId: String, name: String, primaryLocationHint: String? = nil) async throws -> D1Database {
        try await d1Service.createD1Database(accountId: accountId, name: name, primaryLocationHint: primaryLocationHint)
    }
    
    func deleteD1Database(accountId: String, databaseId: String) async throws {
        try await d1Service.deleteD1Database(accountId: accountId, databaseId: databaseId)
    }
    
    func executeD1Query(accountId: String, databaseId: String, sql: String) async throws -> D1QueryResult {
        try await d1Service.executeD1Query(accountId: accountId, databaseId: databaseId, sql: sql)
    }
    
    func listDOObjects(accountId: String, namespaceId: String) async throws -> (items: [DurableObjectInstance], cursor: String?) {
        try await doService.listDOObjects(accountId: accountId, namespaceId: namespaceId)
    }
    
    func listDONamespaces(accountId: String) async throws -> [DurableObjectNamespace] {
        try await doService.listDONamespaces(accountId: accountId)
    }
    
    func getDurableObjectNamespaces(accountId: String) async throws -> [DurableObjectNamespace] {
        try await doService.listDONamespaces(accountId: accountId)
    }
    
    func getHyperdriveConfigs(accountId: String) async throws -> [HyperdriveConfig] {
        try await hyperdriveService.getHyperdriveConfigs(accountId: accountId)
    }
    
    func listHyperdriveConfigs(accountId: String) async throws -> [HyperdriveConfig] {
        try await hyperdriveService.listHyperdriveConfigs(accountId: accountId)
    }
    
    func createHyperdriveConfig(accountId: String, payload: HyperdriveCreate) async throws -> HyperdriveConfig {
        try await hyperdriveService.createHyperdriveConfig(accountId: accountId, payload: payload)
    }
    
    func deleteHyperdriveConfig(accountId: String, configId: String) async throws {
        try await hyperdriveService.deleteHyperdriveConfig(accountId: accountId, configId: configId)
    }
    
    // MARK: - Zero Trust (Tunnels, Turnstile, Access, Gateway)
    
    func getTunnels(accountId: String) async throws -> [CFTunnel] {
        try await tunnelService.getTunnels(accountId: accountId)
    }
    
    func createTunnel(accountId: String, name: String) async throws -> CFTunnel {
        try await tunnelService.createTunnel(accountId: accountId, name: name)
    }
    
    func deleteTunnel(accountId: String, tunnelId: String) async throws {
        try await tunnelService.deleteTunnel(accountId: accountId, tunnelId: tunnelId)
    }
    
    func getTunnelConfigurations(accountId: String, tunnelId: String) async throws -> [TunnelIngressRule] {
        try await tunnelService.getTunnelConfigurations(accountId: accountId, tunnelId: tunnelId)
    }
    
    func updateTunnelConfigurations(accountId: String, tunnelId: String, ingressRules: [TunnelIngressRule]) async throws {
        try await tunnelService.updateTunnelConfigurations(accountId: accountId, tunnelId: tunnelId, ingressRules: ingressRules)
    }
    
    func getTunnelToken(accountId: String, tunnelId: String) async throws -> String? {
        try await tunnelService.getTunnelToken(accountId: accountId, tunnelId: tunnelId)
    }
    
    func getTurnstileWidgets(accountId: String) async throws -> [TurnstileWidget] {
        try await turnstileService.getTurnstileWidgets(accountId: accountId)
    }
    
    func createTurnstileWidget(accountId: String, input: TurnstileCreateInput) async throws -> TurnstileWidget {
        try await turnstileService.createTurnstileWidget(accountId: accountId, input: input)
    }
    
    func updateTurnstileWidget(accountId: String, sitekey: String, input: TurnstileUpdateInput) async throws -> TurnstileWidget {
        try await turnstileService.updateTurnstileWidget(accountId: accountId, sitekey: sitekey, input: input)
    }
    
    func deleteTurnstileWidget(accountId: String, sitekey: String) async throws {
        try await turnstileService.deleteTurnstileWidget(accountId: accountId, sitekey: sitekey)
    }
    
    func rotateTurnstileSecret(accountId: String, sitekey: String, invalidateImmediately: Bool = false) async throws -> String {
        try await turnstileService.rotateTurnstileSecret(accountId: accountId, sitekey: sitekey, invalidateImmediately: invalidateImmediately)
    }
    
    func listAccessApps(accountId: String) async throws -> [AccessApp] {
        try await accessService.listAccessApps(accountId: accountId)
    }
    
    func deleteAccessApp(accountId: String, appId: String) async throws {
        try await accessService.deleteAccessApp(accountId: accountId, appId: appId)
    }
    
    func listAccessPolicies(accountId: String, appId: String) async throws -> [AccessPolicy] {
        try await accessService.listAccessPolicies(accountId: accountId, appId: appId)
    }
    
    func listGatewayRules(accountId: String) async throws -> [GatewayRule] {
        try await gatewayService.getGatewayRules(accountId: accountId)
    }
    
    func deleteGatewayRule(accountId: String, ruleId: String) async throws {
        try await gatewayService.deleteGatewayRule(accountId: accountId, ruleId: ruleId)
    }
    
    // MARK: - AI & Queues
    
    func getAIGateways(accountId: String) async throws -> [AIGateway] {
        try await aiService.getAIGateways(accountId: accountId)
    }
    
    func createAIGateway(accountId: String, id: String) async throws {
        try await aiService.createAIGateway(accountId: accountId, id: id)
    }
    
    func deleteAIGateway(accountId: String, id: String) async throws {
        try await aiService.deleteAIGateway(accountId: accountId, id: id)
    }
    
    func getWorkersAIModels(accountId: String) async throws -> [AIModel] {
        try await aiService.getWorkersAIModels(accountId: accountId)
    }
    
    func runAIChat(accountId: String, model: String, messages: [[String: String]]) async throws -> String {
        try await aiService.runAIChat(accountId: accountId, model: model, messages: messages)
    }
    
    func getQueues(accountId: String) async throws -> [CFQueue] {
        try await queueService.getQueues(accountId: accountId)
    }
    
    func listQueues(accountId: String) async throws -> [CFQueue] {
        try await queueService.listQueues(accountId: accountId)
    }
    
    func createQueue(accountId: String, name: String) async throws -> CFQueue {
        try await queueService.createQueue(accountId: accountId, name: name)
    }
    
    func deleteQueue(accountId: String, queueId: String) async throws {
        try await queueService.deleteQueue(accountId: accountId, queueId: queueId)
    }
    
    func purgeQueue(accountId: String, queueId: String) async throws {
        try await queueService.purgeQueue(accountId: accountId, queueId: queueId)
    }
    
    // MARK: - Bulk Redirects
    
    func listRedirectLists(accountId: String) async throws -> [RedirectList] {
        try await bulkRedirectService.listRedirectLists(accountId: accountId)
    }
    
    func createRedirectList(accountId: String, name: String, description: String?) async throws -> RedirectList {
        try await bulkRedirectService.createRedirectList(accountId: accountId, name: name, description: description)
    }
    
    func deleteRedirectList(accountId: String, listId: String) async throws {
        try await bulkRedirectService.deleteRedirectList(accountId: accountId, listId: listId)
    }
    
    func listRedirectListItems(accountId: String, listId: String) async throws -> [RedirectListItem] {
        try await bulkRedirectService.listRedirectListItems(accountId: accountId, listId: listId)
    }
    
    func createRedirectListItems(accountId: String, listId: String, items: [RedirectItemDetail]) async throws -> String {
        try await bulkRedirectService.createRedirectListItems(accountId: accountId, listId: listId, items: items)
    }
    
    func deleteRedirectListItems(accountId: String, listId: String, itemIds: [String]) async throws -> String {
        try await bulkRedirectService.deleteRedirectListItems(accountId: accountId, listId: listId, itemIds: itemIds)
    }
    
    // MARK: - Audit Logs & Alerts
    
    func getAuditLogs(accountId: String) async throws -> [AuditLog] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/audit_logs")
        let (logs, _): ([AuditLog]?, ResultInfo?) = try await client.performRequest(request)
        return logs ?? []
    }
    
    func listAvailableAlertTypes(accountId: String) async throws -> [AlertingAvailableType] {
        try await alertingService.listAvailableAlertTypes(accountId: accountId)
    }
    
    func listAlertingWebhooks(accountId: String) async throws -> [AlertingWebhookDestination] {
        try await alertingService.listAlertingWebhooks(accountId: accountId)
    }
    
    func listAlertingPolicies(accountId: String) async throws -> [AlertingPolicy] {
        try await alertingService.listAlertingPolicies(accountId: accountId)
    }
    
    func deleteAlertingPolicy(accountId: String, policyId: String) async throws {
        try await alertingService.deleteAlertingPolicy(accountId: accountId, policyId: policyId)
    }
    
    // MARK: - DevTools Diagnostic Forwarders
    
    func performDNSLookup(domain: String, type: String = "A") async throws -> DNSLookupResult {
        try await devToolsService.performDNSLookup(domain: domain, type: type)
    }
    
    func inspectHTTPHeaders(urlString: String) async throws -> HTTPInspectionResult {
        try await devToolsService.inspectHTTPHeaders(urlString: urlString)
    }
    
    func inspectSSLCertificate(domain: String) async throws -> SSLCertDetails {
        try await devToolsService.inspectSSLCertificate(domain: domain)
    }
    
    func lookupIP(target: String) async throws -> IPLookupResult {
        try await devToolsService.lookupIP(target: target)
    }
    
    func getCloudflareIPs() async throws -> ([String], [String]) {
        try await devToolsService.getCloudflareIPs()
    }
    
    func getCFTrace(host: String = "www.cloudflare.com") async throws -> [HTTPHeaderItem] {
        try await devToolsService.getCFTrace(host: host)
    }
    
    func fetchGraphQLAnalytics(zoneTag: String, days: Int) async throws -> AnalyticsViewerData {
        try await analyticsService.fetchGraphQLAnalytics(zoneTag: zoneTag, days: days)
    }
}
