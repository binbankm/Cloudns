import Foundation

/// Cloudflare Workers 脚本、触发器与 Secrets 领域服务抽象协议
protocol WorkerServiceProtocol: Sendable {
    func getWorkers(accountId: String) async throws -> [WorkerScript]
    func listWorkers(accountId: String) async throws -> [WorkerScript]
    func deleteWorker(accountId: String, scriptName: String) async throws
    func getWorkerContent(accountId: String, scriptName: String) async throws -> WorkerScriptContentResult
    func getWorkerScriptContent(accountId: String, scriptName: String) async throws -> String
    func uploadWorkerScript(accountId: String, scriptName: String, code: String, isModule: Bool) async throws
    func getWorkerBindings(accountId: String, scriptName: String) async throws -> [WorkerBinding]
    func patchWorkerBindings(accountId: String, scriptName: String, bindings: [WorkerBinding]) async throws
    func getWorkerSubdomain(accountId: String, scriptName: String) async throws -> WorkerSubdomain?
    func setWorkerSubdomain(accountId: String, scriptName: String, enabled: Bool) async throws
    func getWorkerSchedules(accountId: String, scriptName: String) async throws -> [WorkerSchedule]
    func putWorkerSchedules(accountId: String, scriptName: String, crons: [String]) async throws
    func getWorkerSecrets(accountId: String, scriptName: String) async throws -> [WorkerSecret]
    func putWorkerSecret(accountId: String, scriptName: String, name: String, text: String) async throws
    func deleteWorkerSecret(accountId: String, scriptName: String, name: String) async throws
    func getWorkerCustomDomains(accountId: String, scriptName: String) async throws -> [WorkerCustomDomain]
    func attachWorkerDomain(accountId: String, scriptName: String, hostname: String, zoneId: String) async throws
    func detachWorkerDomain(accountId: String, domainId: String) async throws
    func createWorkerTailSession(accountId: String, scriptName: String) async throws -> WorkerTailSession
    func deleteWorkerTailSession(accountId: String, scriptName: String, tailId: String) async throws
    func testWorkerDispatch(urlString: String, httpMethod: String, headers: [String: String], body: String?) async throws -> HTTPInspectionResult
    func getWorkerDeployments(accountId: String, scriptName: String) async throws -> [WorkerDeployment]
    func rollbackWorkerDeployment(accountId: String, scriptName: String, deploymentId: String) async throws
}

/// 统一的 Cloudflare Workers 脚本、触发器与 Secrets 领域服务
final class WorkerService: WorkerServiceProtocol {
    // MARK: - Lifecycle & Dependencies
    static let shared = WorkerService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    // MARK: - Scripts CRUD API
    func getWorkers(accountId: String) async throws -> [WorkerScript] {
        try await listWorkers(accountId: accountId)
    }
    
    func listWorkers(accountId: String) async throws -> [WorkerScript] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts")
        let (scripts, _): ([WorkerScript]?, ResultInfo?) = try await client.performRequest(request)
        return scripts ?? []
    }
    
    func deleteWorkerScript(accountId: String, scriptName: String) async throws {
        try await deleteWorker(accountId: accountId, scriptName: scriptName)
    }
    
    func deleteWorker(accountId: String, scriptName: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)", method: "DELETE")
        struct DeleteRes: Codable { let id: String? }
        let (_, _): (DeleteRes?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func getWorkerContent(accountId: String, scriptName: String) async throws -> WorkerScriptContentResult {
        let text = try await getWorkerScriptContent(accountId: accountId, scriptName: scriptName)
        return WorkerScriptContentResult(rawCode: text, modules: [WorkerModuleItem(name: "\(scriptName).js", code: text, isMain: true)], mainModuleName: "\(scriptName).js")
    }
    
    func getWorkerScriptContent(accountId: String, scriptName: String) async throws -> String {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)", contentType: "")
        let data = try await client.performDataRequest(request)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func uploadWorkerScript(accountId: String, scriptName: String, code: String, isModule: Bool = false) async throws {
        if isModule {
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()
            
            // 1. Metadata Part
            let metadataJSON: [String: Any] = [
                "main_module": "\(scriptName).js",
                "bindings_inherit": true
            ]
            let metadataData = try JSONSerialization.data(withJSONObject: metadataJSON)
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"metadata\"; filename=\"blob\"\r\n".utf8))
            body.append(Data("Content-Type: application/json\r\n\r\n".utf8))
            body.append(metadataData)
            body.append(Data("\r\n".utf8))
            
            // 2. Module Script Part
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(scriptName).js\"; filename=\"\(scriptName).js\"\r\n".utf8))
            body.append(Data("Content-Type: application/javascript+module\r\n\r\n".utf8))
            body.append(code.data(using: .utf8) ?? Data())
            body.append(Data("\r\n--\(boundary)--\r\n".utf8))
            
            let request = try factory.createAuthenticatedRequest(
                path: "accounts/\(accountId)/workers/scripts/\(scriptName)",
                method: "PUT",
                body: body,
                contentType: "multipart/form-data; boundary=\(boundary)"
            )
            struct UploadRes: Codable { let id: String? }
            let (_, _): (UploadRes?, ResultInfo?) = try await client.performRequest(request)
        } else {
            let request = try factory.createAuthenticatedRequest(
                path: "accounts/\(accountId)/workers/scripts/\(scriptName)",
                method: "PUT",
                body: code.data(using: .utf8),
                contentType: "application/javascript"
            )
            struct UploadRes: Codable { let id: String? }
            let (_, _): (UploadRes?, ResultInfo?) = try await client.performRequest(request)
        }
    }
    
    // MARK: - Bindings API
    func getWorkerBindings(accountId: String, scriptName: String) async throws -> [WorkerBinding] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/bindings")
        let (bindings, _): ([WorkerBinding]?, ResultInfo?) = try await client.performRequest(request)
        return bindings ?? []
    }
    
    func patchWorkerBindings(accountId: String, scriptName: String, bindings: [WorkerBinding]) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(bindings)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/bindings", method: "PUT", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Subdomain API
    func getWorkerSubdomain(accountId: String, scriptName: String) async throws -> WorkerSubdomain? {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/subdomain")
        let (sub, _): (WorkerSubdomain?, ResultInfo?) = try await client.performRequest(request)
        return sub
    }
    
    func setWorkerSubdomain(accountId: String, scriptName: String, enabled: Bool) async throws {
        let payload: [String: Any] = ["enabled": enabled]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/subdomain", method: "POST", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Schedules & Triggers API
    func getWorkerSchedules(accountId: String, scriptName: String) async throws -> [WorkerSchedule] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/schedules")
        let (res, _): (WorkerSchedulesResult?, ResultInfo?) = try await client.performRequest(request)
        return res?.schedules ?? []
    }
    
    func putWorkerSchedules(accountId: String, scriptName: String, crons: [String]) async throws {
        let schedules = crons.map { WorkerScheduleInput(cron: $0) }
        let data = try JSONEncoder().encode(schedules)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/schedules", method: "PUT", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Secrets API
    func getWorkerSecrets(accountId: String, scriptName: String) async throws -> [WorkerSecret] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/secrets")
        let (sec, _): ([WorkerSecret]?, ResultInfo?) = try await client.performRequest(request)
        return sec ?? []
    }
    
    func putWorkerSecret(accountId: String, scriptName: String, name: String, text: String) async throws {
        let payload: [String: Any] = ["name": name, "text": text, "type": "secret_text"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/secrets", method: "PUT", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func deleteWorkerSecret(accountId: String, scriptName: String, name: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/secrets/\(name)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Custom Domains API
    func getWorkerCustomDomains(accountId: String, scriptName: String) async throws -> [WorkerCustomDomain] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/domains/records")
        let (doms, _): ([WorkerCustomDomain]?, ResultInfo?) = try await client.performRequest(request)
        return (doms ?? []).filter { $0.service == scriptName }
    }
    
    func attachWorkerDomain(accountId: String, scriptName: String, hostname: String, zoneId: String) async throws {
        let payload: [String: Any] = ["hostname": hostname, "zone_id": zoneId, "service": scriptName, "environment": "production"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/domains/records", method: "PUT", body: data)
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func detachWorkerDomain(accountId: String, domainId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/domains/records/\(domainId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Tail Sessions & Live Logs API
    func createWorkerTailSession(accountId: String, scriptName: String) async throws -> WorkerTailSession {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/tails", method: "POST")
        let (session, _): (WorkerTailSession?, ResultInfo?) = try await client.performRequest(request)
        guard let s = session else { throw APIError.cloudflareError("Failed to create tail session.") }
        return s
    }
    
    func deleteWorkerTailSession(accountId: String, scriptName: String, tailId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/tails/\(tailId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    // MARK: - Dispatch & Test API
    func testWorkerDispatch(urlString: String, httpMethod: String, headers: [String: String], body: String?) async throws -> HTTPInspectionResult {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.timeoutInterval = 15.0
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        if let b = body, !b.isEmpty { request.httpBody = b.data(using: .utf8) }
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        let session = URLSession(configuration: config)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let (asyncBytes, response) = try await session.bytes(for: request)
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        
        var headerItems: [HTTPHeaderItem] = []
        for (k, v) in httpResponse.allHeaderFields { headerItems.append(HTTPHeaderItem(key: "\(k)", value: "\(v)")) }
        
        // 内存安全防护：限制最大读取 1MB (1,048,576 字节)，杜绝大文件耗尽内存
        let maxBytes = 1024 * 1024
        var collectedData = Data()
        var isTruncated = false
        
        for try await byte in asyncBytes {
            if collectedData.count >= maxBytes {
                isTruncated = true
                break
            }
            collectedData.append(byte)
        }
        
        var bodyString = String(bytes: collectedData, encoding: .utf8) ?? ""
        if isTruncated {
            bodyString += "\n\n⚠️ [Response truncated: payload exceeded 1MB memory safety limit]"
        }
        
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
    
    // MARK: - Deployments & Rollbacks API
    func getWorkerDeployments(accountId: String, scriptName: String) async throws -> [WorkerDeployment] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/deployments")
        let rawData = try await client.performDataRequest(request)
        
        // 1. { "result": { "deployments": [...] } }
        struct ResWithDeployments: Codable {
            let result: WorkerDeploymentsResult?
        }
        if let decoded = try? JSONDecoder().decode(ResWithDeployments.self, from: rawData), let list = decoded.result?.deployments {
            return list
        }
        
        // 2. { "result": [WorkerDeployment] }
        struct ResWithArray: Codable {
            let result: [WorkerDeployment]?
        }
        if let decoded = try? JSONDecoder().decode(ResWithArray.self, from: rawData), let list = decoded.result {
            return list
        }
        
        // 3. { "deployments": [WorkerDeployment] }
        if let direct = try? JSONDecoder().decode(WorkerDeploymentsResult.self, from: rawData), let list = direct.deployments {
            return list
        }
        
        // 4. [WorkerDeployment]
        if let directList = try? JSONDecoder().decode([WorkerDeployment].self, from: rawData) {
            return directList
        }
        
        return []
    }
    
    func rollbackWorkerDeployment(accountId: String, scriptName: String, deploymentId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/workers/scripts/\(scriptName)/deployments/\(deploymentId)/rollback", method: "POST")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
