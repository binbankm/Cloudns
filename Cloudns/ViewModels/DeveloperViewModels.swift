import Foundation
import SwiftUI
import Combine

@MainActor
class DeveloperHubViewModel: ObservableObject {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    
    @Published var workers: [WorkerScript] = []
    @Published var pagesProjects: [PagesProject] = []
    @Published var r2Buckets: [R2Bucket] = []
    @Published var kvNamespaces: [KVNamespace] = []
    @Published var d1Databases: [D1Database] = []
    @Published var tunnels: [CFTunnel] = []
    
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    var activeTunnelCount: Int {
        tunnels.filter { $0.isHealthy }.count
    }
    
    func fetchOverview(isRefresh: Bool = false) async {
        if !isRefresh && hasFetchedData { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch Accounts
            let fetchedAccounts = try await apiClient.getAccounts()
            self.accounts = fetchedAccounts
            
            let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
            let currentAcc = fetchedAccounts.first(where: { $0.name == activeEmail || $0.id == activeEmail }) ?? fetchedAccounts.first
            self.selectedAccount = currentAcc
            
            guard let accountId = currentAcc?.id, !accountId.isEmpty else {
                self.hasFetchedData = true
                self.isLoading = false
                return
            }
            
            // 2. Concurrently fetch developer resources
            async let fetchWorkers = (try? await apiClient.getWorkers(accountId: accountId)) ?? []
            async let fetchPages = (try? await apiClient.getPagesProjects(accountId: accountId)) ?? []
            async let fetchR2 = (try? await apiClient.getR2Buckets(accountId: accountId)) ?? []
            async let fetchKV = (try? await apiClient.getKVNamespaces(accountId: accountId)) ?? []
            async let fetchD1 = (try? await apiClient.getD1Databases(accountId: accountId)) ?? []
            async let fetchTunnels = (try? await apiClient.getTunnels(accountId: accountId)) ?? []
            
            let (w, p, r, k, d, t) = await (fetchWorkers, fetchPages, fetchR2, fetchKV, fetchD1, fetchTunnels)
            
            self.workers = w
            self.pagesProjects = p
            self.r2Buckets = r
            self.kvNamespaces = k
            self.d1Databases = d
            self.tunnels = t
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load developer services: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

@MainActor
class WorkersViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var workers: [WorkerScript] = []
    @Published var pages: [PagesProject] = []
    @Published var selectedSegment = 0 // 0: Workers, 1: Pages
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredWorkers: [WorkerScript] {
        if searchText.isEmpty { return workers }
        return workers.filter { $0.id.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredPages: [PagesProject] {
        if searchText.isEmpty { return pages }
        return pages.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchW = apiClient.getWorkers(accountId: accountId)
            async let fetchP = apiClient.getPagesProjects(accountId: accountId)
            
            let (w, p) = try await (fetchW, fetchP)
            self.workers = w
            self.pages = p
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createWorker(name: String, code: String) async throws {
        try await apiClient.createWorkerScript(accountId: accountId, name: name, code: code)
        await fetchData()
    }
    
    func deleteWorker(name: String) async throws {
        try await apiClient.deleteWorkerScript(accountId: accountId, scriptName: name)
        await fetchData()
    }

    func createPagesProject(name: String, branch: String) async throws {
        _ = try await apiClient.createPagesProject(accountId: accountId, name: name, productionBranch: branch)
        await fetchData()
    }
    
    func deletePagesProject(name: String) async throws {
        try await apiClient.deletePagesProject(accountId: accountId, projectName: name)
        await fetchData()
    }
}

@MainActor
class WorkerDetailViewModel: ObservableObject {
    let accountId: String
    @Published var worker: WorkerScript
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var scriptResult: WorkerScriptContentResult?
    @Published var modules: [WorkerModuleItem] = []
    @Published var selectedModule: WorkerModuleItem?
    @Published var scriptContent: String = ""
    @Published var bindings: [WorkerBinding] = []
    @Published var subdomain: WorkerSubdomain?
    @Published var schedules: [WorkerSchedule] = []
    @Published var isSubdomainUpdating = false
    @Published var isLoading = false
    @Published var isDeploying = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, worker: WorkerScript) {
        self.accountId = accountId
        self.worker = worker
    }
    
    func selectModule(_ module: WorkerModuleItem) {
        self.selectedModule = module
    }
    
    func fetchDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchCode = apiClient.getWorkerScriptContent(accountId: accountId, scriptName: worker.id)
            async let fetchBindings = (try? await apiClient.getWorkerBindings(accountId: accountId, scriptName: worker.id)) ?? []
            async let fetchSub = (try? await apiClient.getWorkerSubdomain(accountId: accountId, scriptName: worker.id))
            async let fetchSched = (try? await apiClient.getWorkerSchedules(accountId: accountId, scriptName: worker.id)) ?? []
            async let fetchWorkers = (try? await apiClient.getWorkers(accountId: accountId)) ?? []
            
            let (result, b, sub, sched, workersList) = await (try fetchCode, fetchBindings, fetchSub, fetchSched, fetchWorkers)
            self.scriptResult = result
            self.scriptContent = result.rawCode
            self.modules = result.modules
            self.selectedModule = result.modules.first(where: { $0.isMain }) ?? result.modules.first
            self.bindings = b
            self.subdomain = sub
            self.schedules = sched
            
            if let latestWorker = workersList.first(where: { $0.id == self.worker.id }) {
                self.worker = latestWorker
            }
            
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleSubdomain(enabled: Bool) async {
        isSubdomainUpdating = true
        do {
            try await apiClient.setWorkerSubdomain(accountId: accountId, scriptName: worker.id, enabled: enabled)
            self.subdomain = try? await apiClient.getWorkerSubdomain(accountId: accountId, scriptName: worker.id)
            ToastManager.shared.showSuccess("Subdomain Updated", message: enabled ? "workers.dev enabled" : "workers.dev disabled")
        } catch {
            ToastManager.shared.showError("Failed to update subdomain", message: error.localizedDescription)
        }
        isSubdomainUpdating = false
    }

    func deployScript(code: String, isModule: Bool) async throws {
        isDeploying = true
        defer { isDeploying = false }
        try await apiClient.createWorkerScript(accountId: accountId, name: worker.id, code: code, isModule: isModule)
        await fetchDetails()
    }
}

@MainActor
class WorkerTriggersViewModel: ObservableObject {
    let accountId: String
    let scriptName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var schedules: [WorkerSchedule] = []
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
    }
    
    func fetchSchedules() async {
        isLoading = true
        errorMessage = nil
        do {
            self.schedules = try await apiClient.getWorkerSchedules(accountId: accountId, scriptName: scriptName)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func addSchedule(cron: String) async throws {
        var currentCrons = schedules.map(\.cron)
        let trimmed = cron.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !currentCrons.contains(trimmed) else { return }
        currentCrons.append(trimmed)
        try await apiClient.putWorkerSchedules(accountId: accountId, scriptName: scriptName, crons: currentCrons)
        await fetchSchedules()
    }
    
    func deleteSchedule(cron: String) async throws {
        let updatedCrons = schedules.map(\.cron).filter { $0 != cron }
        try await apiClient.putWorkerSchedules(accountId: accountId, scriptName: scriptName, crons: updatedCrons)
        await fetchSchedules()
    }
}

@MainActor
class WorkerTailViewModel: ObservableObject {
    let accountId: String
    let scriptName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var isStreaming = false
    @Published var events: [TailTraceItem] = []
    @Published var searchText = ""
    @Published var selectedFilter = 0 // 0: All, 1: Logs Only, 2: Exceptions Only
    @Published var errorMessage: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var currentSessionId: String?
    private var isTaskCancelled = false
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
    }
    
    var filteredEvents: [TailTraceItem] {
        var list = events
        if selectedFilter == 1 {
            list = list.filter { ($0.logs?.isEmpty == false) }
        } else if selectedFilter == 2 {
            list = list.filter { ($0.exceptions?.isEmpty == false) || ($0.outcome != "ok" && $0.outcome != nil) }
        }
        
        if searchText.isEmpty { return list }
        return list.filter { item in
            if let url = item.event?.request?.url, url.localizedCaseInsensitiveContains(searchText) { return true }
            if let logs = item.logs {
                for log in logs {
                    if let msgs = log.message {
                        for m in msgs {
                            if m.displayText.localizedCaseInsensitiveContains(searchText) { return true }
                        }
                    }
                }
            }
            if let exceptions = item.exceptions {
                for ex in exceptions {
                    if let msg = ex.message, msg.localizedCaseInsensitiveContains(searchText) { return true }
                }
            }
            return false
        }
    }
    
    func startStream() async {
        guard !isStreaming else { return }
        errorMessage = nil
        isStreaming = true
        isTaskCancelled = false
        
        do {
            let session = try await apiClient.createWorkerTailSession(accountId: accountId, scriptName: scriptName)
            self.currentSessionId = session.id
            guard let url = URL(string: session.url) else {
                throw APIError.invalidURL
            }
            
            let task = URLSession.shared.webSocketTask(with: url, protocols: ["trace-v1"])
            self.webSocketTask = task
            task.resume()
            
            // Send trace-v1 filter setup
            try await task.send(.string(#"{"filters":[],"debug":false}"#))
            
            startReceiveLoop(for: task)
        } catch {
            self.errorMessage = "Failed to connect: \(error.localizedDescription)"
            self.isStreaming = false
        }
    }
    
    private func startReceiveLoop(for task: URLSessionWebSocketTask) {
        Task { [weak self] in
            while true {
                guard let self = self, self.isStreaming, !self.isTaskCancelled else { break }
                do {
                    let message = try await task.receive()
                    let data: Data?
                    switch message {
                    case .string(let text):
                        data = text.data(using: .utf8)
                    case .data(let d):
                        data = d
                    @unknown default:
                        data = nil
                    }
                    
                    if let d = data, let item = try? JSONDecoder().decode(TailTraceItem.self, from: d) {
                        self.events.insert(item, at: 0)
                        if self.events.count > 500 {
                            self.events.removeLast()
                        }
                    }
                } catch {
                    if !self.isTaskCancelled {
                        self.errorMessage = "Disconnected: \(error.localizedDescription)"
                        self.isStreaming = false
                    }
                    break
                }
            }
        }
    }
    
    func stopStream() {
        isTaskCancelled = true
        isStreaming = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        if let sid = currentSessionId {
            Task {
                try? await apiClient.deleteWorkerTailSession(accountId: accountId, scriptName: scriptName, tailId: sid)
            }
            currentSessionId = nil
        }
    }
    
    func clearLogs() {
        events.removeAll()
    }
}

@MainActor
class PagesProjectDetailViewModel: ObservableObject {
    let accountId: String
    let project: PagesProject
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var deployments: [PagesDeployment] = []
    @Published var domains: [PagesDomain] = []
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, project: PagesProject) {
        self.accountId = accountId
        self.project = project
    }
    
    func fetchProjectDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchDeps = apiClient.getPagesDeployments(accountId: accountId, projectName: project.name)
            async let fetchDoms = (try? await apiClient.getPagesDomains(accountId: accountId, projectName: project.name)) ?? []
            
            let (deps, doms) = await (try fetchDeps, fetchDoms)
            self.deployments = deps
            self.domains = doms
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addDomain(name: String) async throws {
        try await apiClient.addPagesDomain(accountId: accountId, projectName: project.name, domain: name)
        await fetchProjectDetails()
    }
    
    func deleteDomain(name: String) async throws {
        try await apiClient.deletePagesDomain(accountId: accountId, projectName: project.name, domain: name)
        await fetchProjectDetails()
    }

    func rollbackDeployment(id: String) async throws {
        try await apiClient.rollbackPagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }

    func retryDeployment(id: String) async throws {
        try await apiClient.retryPagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }

    func deleteDeployment(id: String) async throws {
        try await apiClient.deletePagesDeployment(accountId: accountId, projectName: project.name, deploymentId: id)
        await fetchProjectDetails()
    }
}

@MainActor
class PagesDeploymentDetailViewModel: ObservableObject {
    let accountId: String
    let projectName: String
    let deployment: PagesDeployment
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var logs: [PagesDeploymentLog] = []
    @Published var isLoadingLogs = false
    @Published var errorMessage: String?
    
    init(accountId: String, projectName: String, deployment: PagesDeployment) {
        self.accountId = accountId
        self.projectName = projectName
        self.deployment = deployment
    }
    
    func fetchLogs() async {
        isLoadingLogs = true
        errorMessage = nil
        do {
            self.logs = try await apiClient.getPagesDeploymentLogs(accountId: accountId, projectName: projectName, deploymentId: deployment.id)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoadingLogs = false
    }
}

@MainActor
class R2ViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var buckets: [R2Bucket] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredBuckets: [R2Bucket] {
        if searchText.isEmpty { return buckets }
        return buckets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchBuckets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.buckets = try await apiClient.getR2Buckets(accountId: accountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func createBucket(name: String, locationHint: String? = nil) async throws {
        _ = try await apiClient.createR2Bucket(accountId: accountId, name: name, locationHint: locationHint)
        await fetchBuckets()
    }

    func deleteBucket(bucketName: String) async throws {
        try await apiClient.deleteR2Bucket(accountId: accountId, bucketName: bucketName)
        await fetchBuckets()
    }
}

@MainActor
class R2BucketDetailViewModel: ObservableObject {
    let accountId: String
    let bucket: R2Bucket
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var objects: [R2Object] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, bucket: R2Bucket) {
        self.accountId = accountId
        self.bucket = bucket
    }
    
    var filteredObjects: [R2Object] {
        if searchText.isEmpty { return objects }
        return objects.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchObjects() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.objects = try await apiClient.getR2Objects(accountId: accountId, bucketName: bucket.name)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func deleteObject(key: String) async throws {
        try await apiClient.deleteR2Object(accountId: accountId, bucketName: bucket.name, objectKey: key)
        await fetchObjects()
    }

    func uploadObject(key: String, data: Data, contentType: String = "application/octet-stream") async throws {
        try await apiClient.putR2Object(accountId: accountId, bucketName: bucket.name, objectKey: key, data: data, contentType: contentType)
        await fetchObjects()
    }
}

@MainActor
class KVViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var namespaces: [KVNamespace] = []
    @Published var d1Databases: [D1Database] = []
    @Published var selectedSegment = 0 // 0: KV, 1: D1
    
    @Published var keys: [KVKey] = []
    @Published var selectedKey: String?
    @Published var selectedKeyValue: String?
    @Published var isValueLoading = false
    
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchKV = apiClient.getKVNamespaces(accountId: accountId)
            async let fetchD1 = apiClient.getD1Databases(accountId: accountId)
            
            let (k, d) = try await (fetchKV, fetchD1)
            self.namespaces = k
            self.d1Databases = d
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func createNamespace(title: String) async throws {
        _ = try await apiClient.createKVNamespace(accountId: accountId, title: title)
        await fetchData()
    }

    func deleteNamespace(namespaceId: String) async throws {
        try await apiClient.deleteKVNamespace(accountId: accountId, namespaceId: namespaceId)
        await fetchData()
    }

    func createDatabase(name: String, locationHint: String? = nil) async throws {
        _ = try await apiClient.createD1Database(accountId: accountId, name: name, primaryLocationHint: locationHint)
        await fetchData()
    }

    func deleteDatabase(databaseId: String) async throws {
        try await apiClient.deleteD1Database(accountId: accountId, databaseId: databaseId)
        await fetchData()
    }
    
    func fetchKeys(for namespaceId: String) async {
        isLoading = true
        do {
            self.keys = try await apiClient.getKVKeys(accountId: accountId, namespaceId: namespaceId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchValue(namespaceId: String, key: String) async {
        isValueLoading = true
        selectedKey = key
        selectedKeyValue = nil
        do {
            self.selectedKeyValue = try await apiClient.getKVValue(accountId: accountId, namespaceId: namespaceId, key: key)
        } catch {
            self.selectedKeyValue = "Error reading value: \(error.localizedDescription)"
        }
        isValueLoading = false
    }
    
    func saveKey(namespaceId: String, key: String, value: String, ttl: Int? = nil) async throws {
        try await apiClient.saveKVValue(accountId: accountId, namespaceId: namespaceId, key: key, value: value, expirationTTL: ttl)
        await fetchKeys(for: namespaceId)
    }
    
    func deleteKey(namespaceId: String, key: String) async throws {
        try await apiClient.deleteKVKey(accountId: accountId, namespaceId: namespaceId, key: key)
        await fetchKeys(for: namespaceId)
    }
}

@MainActor
class KVNamespaceDetailViewModel: ObservableObject {
    let accountId: String
    let namespace: KVNamespace
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var keys: [KVKey] = []
    @Published var selectedKey: String?
    @Published var selectedKeyValue: String?
    @Published var isValueLoading = false
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, namespace: KVNamespace) {
        self.accountId = accountId
        self.namespace = namespace
    }
    
    func fetchKeys() async {
        isLoading = true
        errorMessage = nil
        do {
            self.keys = try await apiClient.getKVKeys(accountId: accountId, namespaceId: namespace.id)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchValue(key: String) async {
        isValueLoading = true
        selectedKey = key
        selectedKeyValue = nil
        do {
            self.selectedKeyValue = try await apiClient.getKVValue(accountId: accountId, namespaceId: namespace.id, key: key)
        } catch {
            self.selectedKeyValue = "Error reading value: \(error.localizedDescription)"
        }
        isValueLoading = false
    }
    
    func saveKey(key: String, value: String, ttl: Int? = nil) async throws {
        try await apiClient.saveKVValue(accountId: accountId, namespaceId: namespace.id, key: key, value: value, expirationTTL: ttl)
        await fetchKeys()
    }
    
    func deleteKey(key: String) async throws {
        try await apiClient.deleteKVKey(accountId: accountId, namespaceId: namespace.id, key: key)
        await fetchKeys()
    }
}

@MainActor
class D1ConsoleViewModel: ObservableObject {
    let accountId: String
    let database: D1Database
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var tables: [String] = []
    @Published var sqlInput: String = "SELECT name, type FROM sqlite_master WHERE type='table';"
    @Published var queryResult: D1QueryResult?
    @Published var isExecuting = false
    @Published var isLoadingTables = false
    @Published var errorMessage: String?
    
    let sqlPresets: [(name: String, sql: String)] = [
        ("Table List", "SELECT name, type FROM sqlite_master WHERE type='table';"),
        ("All Sequences", "SELECT * FROM sqlite_sequence;"),
        ("Table Info", "PRAGMA table_list;")
    ]
    
    init(accountId: String, database: D1Database) {
        self.accountId = accountId
        self.database = database
    }
    
    func fetchTables() async {
        isLoadingTables = true
        do {
            let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' ORDER BY name;"
            let res = try await apiClient.executeD1Query(accountId: accountId, databaseId: database.uuid, sql: sql)
            self.tables = res.rows.compactMap { $0["name"] }
        } catch {
            print("Failed to fetch tables: \(error.localizedDescription)")
        }
        isLoadingTables = false
    }
    
    func runQuery() async {
        let trimmed = sqlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isExecuting = true
        errorMessage = nil
        
        do {
            self.queryResult = try await apiClient.executeD1Query(accountId: accountId, databaseId: database.uuid, sql: trimmed)
            // If query modified schema, re-fetch tables
            if trimmed.localizedCaseInsensitiveContains("CREATE TABLE") || trimmed.localizedCaseInsensitiveContains("DROP TABLE") {
                await fetchTables()
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isExecuting = false
    }
}

@MainActor
class TunnelsViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var tunnels: [CFTunnel] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredTunnels: [CFTunnel] {
        if searchText.isEmpty { return tunnels }
        return tunnels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchTunnels() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.tunnels = try await apiClient.getTunnels(accountId: accountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createTunnel(name: String) async -> Bool {
        do {
            let created = try await apiClient.createTunnel(accountId: accountId, name: name)
            tunnels.insert(created, at: 0)
            ToastManager.shared.showSuccess("Tunnel Created", message: name)
            return true
        } catch {
            ToastManager.shared.showError("Creation Failed", message: error.localizedDescription)
            return false
        }
    }
}

@MainActor
class TunnelDetailViewModel: ObservableObject {
    let accountId: String
    let tunnel: CFTunnel
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var ingressRules: [TunnelIngressRule] = []
    @Published var token: String?
    @Published var isLoading = false
    @Published var isDeleting = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, tunnel: CFTunnel) {
        self.accountId = accountId
        self.tunnel = tunnel
    }
    
    func fetchConfiguration() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchConfig = apiClient.getTunnelConfigurations(accountId: accountId, tunnelId: tunnel.id)
            async let fetchTok = apiClient.getTunnelToken(accountId: accountId, tunnelId: tunnel.id)
            let (rules, tok) = try await (fetchConfig, fetchTok)
            self.ingressRules = rules
            self.token = tok
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addIngressRule(hostname: String, path: String?, service: String) async -> Bool {
        var updated = ingressRules
        let newRule = TunnelIngressRule(hostname: hostname.isEmpty ? nil : hostname, path: path?.isEmpty == true ? nil : path, service: service)
        if let last = updated.last, last.hostname == nil && last.path == nil {
            updated.insert(newRule, at: updated.count - 1)
        } else {
            updated.append(newRule)
            if !updated.contains(where: { $0.hostname == nil && $0.path == nil }) {
                updated.append(TunnelIngressRule(hostname: nil, path: nil, service: "http_status:404"))
            }
        }
        
        do {
            try await apiClient.updateTunnelConfigurations(accountId: accountId, tunnelId: tunnel.id, ingressRules: updated)
            self.ingressRules = updated
            ToastManager.shared.showSuccess("Ingress Rule Added", message: hostname)
            return true
        } catch {
            ToastManager.shared.showError("Save Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteIngressRule(at index: Int) async {
        var updated = ingressRules
        guard index < updated.count else { return }
        updated.remove(at: index)
        if updated.isEmpty || !updated.contains(where: { $0.hostname == nil && $0.path == nil }) {
            updated.append(TunnelIngressRule(hostname: nil, path: nil, service: "http_status:404"))
        }
        do {
            try await apiClient.updateTunnelConfigurations(accountId: accountId, tunnelId: tunnel.id, ingressRules: updated)
            self.ingressRules = updated
            ToastManager.shared.showSuccess("Ingress Rule Deleted", message: "")
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func deleteTunnel() async -> Bool {
        isDeleting = true
        do {
            try await apiClient.deleteTunnel(accountId: accountId, tunnelId: tunnel.id)
            ToastManager.shared.showSuccess("Tunnel Deleted", message: tunnel.name)
            isDeleting = false
            return true
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            isDeleting = false
            return false
        }
    }
}

@MainActor
class DevToolsViewModel: ObservableObject {
    private let apiClient = CloudflareAPIClient.shared
    
    // DNS Dig
    @Published var domainInput = ""
    @Published var selectedRecordType = "A"
    @Published var dnsResult: DNSLookupResult?
    @Published var isDnsLoading = false
    @Published var dnsError: String?
    
    let recordTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "SRV", "CAA", "HTTPS", "PTR", "DNSKEY", "DS", "TLSA"]
    
    // HTTP Inspector
    @Published var httpUrlInput = ""
    @Published var httpResult: HTTPInspectionResult?
    @Published var isHttpLoading = false
    @Published var httpError: String?
    
    func queryDNS() async {
        let target = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isDnsLoading = true
        dnsError = nil
        dnsResult = nil
        
        do {
            let result = try await apiClient.performDNSLookup(domain: target, type: selectedRecordType)
            self.dnsResult = result
        } catch {
            self.dnsError = error.localizedDescription
        }
        
        isDnsLoading = false
    }
    
    func inspectHTTP() async {
        let target = httpUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isHttpLoading = true
        httpError = nil
        httpResult = nil
        
        do {
            let result = try await apiClient.inspectHTTPHeaders(urlString: target)
            self.httpResult = result
        } catch {
            self.httpError = error.localizedDescription
        }
        
        isHttpLoading = false
    }
}

@MainActor
class WorkerSecretsViewModel: ObservableObject {
    let accountId: String
    let scriptName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var selectedTab: String = "variables" // "variables" | "secrets"
    @Published var plainVariables: [WorkerBinding] = []
    @Published var secrets: [WorkerSecret] = []
    @Published var allBindings: [WorkerBinding] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
    }
    
    var filteredVariables: [WorkerBinding] {
        if searchText.isEmpty { return plainVariables }
        return plainVariables.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.text?.localizedCaseInsensitiveContains(searchText) ?? false) }
    }
    
    var filteredSecrets: [WorkerSecret] {
        if searchText.isEmpty { return secrets }
        return secrets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchSecrets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchedSecrets = apiClient.getWorkerSecrets(accountId: accountId, scriptName: scriptName)
            async let fetchedBindings = apiClient.getWorkerBindings(accountId: accountId, scriptName: scriptName)
            
            let (secList, bindList) = try await (fetchedSecrets, fetchedBindings)
            self.secrets = secList
            self.allBindings = bindList
            self.plainVariables = bindList.filter { $0.type == "plain_text" }
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func savePlainVariable(name: String, value: String) async throws {
        var updated = allBindings.filter { $0.name != name }
        updated.append(WorkerBinding(name: name, type: "plain_text", namespaceId: nil, bucketName: nil, databaseId: nil, text: value))
        try await apiClient.patchWorkerBindings(accountId: accountId, scriptName: scriptName, bindings: updated)
        await fetchSecrets()
    }
    
    func deletePlainVariable(name: String) async throws {
        let updated = allBindings.filter { $0.name != name }
        try await apiClient.patchWorkerBindings(accountId: accountId, scriptName: scriptName, bindings: updated)
        await fetchSecrets()
    }
    
    func saveSecret(name: String, value: String) async throws {
        try await apiClient.putWorkerSecret(accountId: accountId, scriptName: scriptName, name: name, text: value)
        await fetchSecrets()
    }
    
    func deleteSecret(name: String) async throws {
        try await apiClient.deleteWorkerSecret(accountId: accountId, scriptName: scriptName, name: name)
        await fetchSecrets()
    }
}

@MainActor
class WorkerTesterViewModel: ObservableObject {
    let scriptName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var targetUrl: String = ""
    @Published var selectedMethod: String = "GET"
    @Published var requestBody: String = ""
    @Published var responseStatusCode: Int?
    @Published var responseStatusText: String?
    @Published var responseDurationMs: Double?
    @Published var responseHeaders: [HTTPHeaderItem] = []
    @Published var responseBody: String?
    @Published var isTesting = false
    @Published var errorMessage: String?
    
    let methods = ["GET", "POST", "PUT", "PATCH", "DELETE"]
    
    init(scriptName: String, initialRoute: String? = nil) {
        self.scriptName = scriptName
        if let route = initialRoute, !route.isEmpty {
            self.targetUrl = "https://" + route.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        } else {
            self.targetUrl = "https://\(scriptName).workers.dev"
        }
    }
    
    func executeDispatch() async {
        let trimmed = targetUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isTesting = true
        errorMessage = nil
        responseStatusCode = nil
        responseStatusText = nil
        responseDurationMs = nil
        responseHeaders = []
        responseBody = nil
        
        do {
            var headers: [String: String] = [:]
            if selectedMethod == "POST" || selectedMethod == "PUT" || selectedMethod == "PATCH" {
                headers["Content-Type"] = "application/json"
            }
            
            let res = try await apiClient.testWorkerDispatch(
                urlString: trimmed,
                httpMethod: selectedMethod,
                headers: headers,
                body: requestBody.isEmpty ? nil : requestBody
            )
            
            self.responseStatusCode = res.statusCode
            self.responseStatusText = res.statusText
            self.responseDurationMs = res.durationMs
            self.responseHeaders = res.responseHeaders
            self.responseBody = res.responseBody
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isTesting = false
    }
}

@MainActor
class IPLookupViewModel: ObservableObject {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var ipInput: String = ""
    @Published var lookupResult: IPLookupResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func queryIP() async {
        let target = ipInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        lookupResult = nil
        
        do {
            self.lookupResult = try await apiClient.lookupIP(target: target)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

@MainActor
class AuditLogsViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var logs: [AuditLog] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredLogs: [AuditLog] {
        if searchText.isEmpty { return logs }
        return logs.filter {
            ($0.action?.type?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.actor?.email?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.resource?.type?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    func fetchLogs() async {
        isLoading = true
        errorMessage = nil
        
        do {
            var targetAccountId = accountId
            if targetAccountId.isEmpty {
                let accounts = try? await apiClient.getAccounts()
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                targetAccountId = accounts?.first(where: { $0.name == activeEmail || $0.id == activeEmail })?.id ?? accounts?.first?.id ?? ""
            }
            
            guard !targetAccountId.isEmpty else {
                self.logs = []
                self.hasFetchedData = true
                self.isLoading = false
                return
            }
            
            self.logs = try await apiClient.getAuditLogs(accountId: targetAccountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

@MainActor
class TurnstileViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var widgets: [TurnstileWidget] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredWidgets: [TurnstileWidget] {
        if searchText.isEmpty { return widgets }
        return widgets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchWidgets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.widgets = try await apiClient.getTurnstileWidgets(accountId: accountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createWidget(name: String, domains: [String], mode: String) async throws -> TurnstileWidget {
        let input = TurnstileCreateInput(name: name, domains: domains, mode: mode)
        let created = try await apiClient.createTurnstileWidget(accountId: accountId, input: input)
        self.widgets.insert(created, at: 0)
        return created
    }
    
    func updateWidget(sitekey: String, name: String, domains: [String], mode: String) async throws {
        let input = TurnstileUpdateInput(name: name, domains: domains, mode: mode)
        let updated = try await apiClient.updateTurnstileWidget(accountId: accountId, sitekey: sitekey, input: input)
        if let idx = widgets.firstIndex(where: { $0.sitekey == sitekey }) {
            widgets[idx] = updated
        }
    }
    
    func deleteWidget(sitekey: String) async throws {
        try await apiClient.deleteTurnstileWidget(accountId: accountId, sitekey: sitekey)
        widgets.removeAll(where: { $0.sitekey == sitekey })
    }
    
    func rotateSecret(sitekey: String, invalidateImmediately: Bool) async throws -> String {
        let newSecret = try await apiClient.rotateTurnstileSecret(accountId: accountId, sitekey: sitekey, invalidateImmediately: invalidateImmediately)
        await fetchWidgets()
        return newSecret
    }
}

@MainActor
class AIGatewaysViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var gateways: [AIGateway] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredGateways: [AIGateway] {
        if searchText.isEmpty { return gateways }
        return gateways.filter { ($0.name ?? $0.id).localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchGateways() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.gateways = try await apiClient.getAIGateways(accountId: accountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createGateway(id: String) async throws {
        try await apiClient.createAIGateway(accountId: accountId, id: id)
        await fetchGateways()
    }
    
    func deleteGateway(id: String) async throws {
        try await apiClient.deleteAIGateway(accountId: accountId, id: id)
        await fetchGateways()
    }
}

@MainActor
class WorkersAIViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var models: [AIModel] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    // Chat Playground
    @Published var chatMessages: [AIChatMessageItem] = []
    @Published var promptInput: String = ""
    @Published var isSendingMessage = false
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredModels: [AIModel] {
        if searchText.isEmpty { return models }
        return models.filter {
            $0.shortName.localizedCaseInsensitiveContains(searchText) ||
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.taskName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var groupedModels: [String: [AIModel]] {
        Dictionary(grouping: filteredModels, by: { $0.taskName })
    }
    
    func fetchModels() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.models = try await apiClient.getWorkersAIModels(accountId: accountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func sendMessage(model: String) async {
        let input = promptInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !isSendingMessage else { return }
        
        let userMsg = AIChatMessageItem(role: "user", content: input)
        chatMessages.append(userMsg)
        promptInput = ""
        isSendingMessage = true
        
        let payloadMessages = chatMessages.filter { !$0.isError }.map { ["role": $0.role, "content": $0.content] }
        
        do {
            let reply = try await apiClient.runAIChat(accountId: accountId, model: model, messages: payloadMessages)
            let assistantMsg = AIChatMessageItem(role: "assistant", content: reply)
            chatMessages.append(assistantMsg)
        } catch {
            let errorMsg = AIChatMessageItem(role: "assistant", content: "Error: \(error.localizedDescription)", isError: true)
            chatMessages.append(errorMsg)
        }
        
        isSendingMessage = false
    }
    
    func clearChat() {
        chatMessages.removeAll()
        promptInput = ""
    }
}

public struct AIChatMessageItem: Identifiable, Equatable {
    public let id = UUID()
    public let role: String // "user" or "assistant"
    public let content: String
    public let timestamp = Date()
    public var isError: Bool = false
    
    public init(role: String, content: String, isError: Bool = false) {
        self.role = role
        self.content = content
        self.isError = isError
    }
}

@MainActor
class CFTraceViewModel: ObservableObject {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var host: String = "www.cloudflare.com"
    @Published var traceFields: [HTTPHeaderItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var coloCode: String? {
        traceFields.first(where: { $0.key == "colo" })?.value
    }
    
    var clientIp: String? {
        traceFields.first(where: { $0.key == "ip" })?.value
    }
    
    var locCountry: String? {
        traceFields.first(where: { $0.key == "loc" })?.value
    }
    
    var warpStatus: String? {
        traceFields.first(where: { $0.key == "warp" })?.value
    }
    
    func queryTrace() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.traceFields = try await apiClient.getCFTrace(host: host)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

@MainActor
class CFIpRangesViewModel: ObservableObject {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var ipv4List: [String] = []
    @Published var ipv6List: [String] = []
    @Published var selectedSegment = 0 // 0: IPv4, 1: IPv6
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    var filteredIPv4: [String] {
        if searchText.isEmpty { return ipv4List }
        return ipv4List.filter { $0.contains(searchText) }
    }
    
    var filteredIPv6: [String] {
        if searchText.isEmpty { return ipv6List }
        return ipv6List.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchIPRanges() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let (v4, v6) = try await apiClient.getCloudflareIPs()
            self.ipv4List = v4
            self.ipv6List = v6
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

@MainActor
class SSLCertInspectorViewModel: ObservableObject {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var domainInput: String = "cloudflare.com"
    @Published var certDetails: SSLCertDetails?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func inspectCert() async {
        let domain = domainInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !domain.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        certDetails = nil
        
        do {
            self.certDetails = try await apiClient.inspectSSLCertificate(domain: domain)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}




