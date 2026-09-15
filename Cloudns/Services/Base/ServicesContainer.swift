import Foundation

/// Central Dependency Injection and Service Locator Container for Cloudns
final class ServicesContainer: @unchecked Sendable {
    static let shared = ServicesContainer()

    // MARK: - 1. Auth & Accounts

    var auth: AuthServiceProtocol = AuthService.shared

    // MARK: - 2. Zones & DNS

    var zones: ZoneServiceProtocol = ZoneService.shared
    var dns: DNSServiceProtocol = DNSService.shared

    // MARK: - 3. Security & SSL

    var ssl: CertificateServiceProtocol = CertificateService.shared
    var securitySettings: SecuritySettingsServiceProtocol = SecuritySettingsService.shared
    var waf: WAFRulesServiceProtocol = WAFRulesService.shared
    var ipAccess: IPAccessRulesServiceProtocol = IPAccessRulesService.shared
    var securityEvents: SecurityEventsServiceProtocol = SecurityEventsService.shared
    var scrapeShield: ScrapeShieldServiceProtocol = ScrapeShieldService.shared

    // MARK: - 4. Performance & Acceleration

    var caching: CachingServiceProtocol = CachingService.shared
    var speed: SpeedSettingsServiceProtocol = SpeedSettingsService.shared
    var network: NetworkSettingsServiceProtocol = NetworkSettingsService.shared

    // MARK: - 5. Rules & Routing

    var redirectRules: RedirectRulesServiceProtocol = RedirectRulesService.shared
    var loadBalancer: LoadBalancerServiceProtocol = LoadBalancerService.shared
    var snippets: SnippetServiceProtocol = SnippetService.shared
    var emailRouting: EmailRoutingServiceProtocol = EmailRoutingService.shared

    // MARK: - 6. Developer Ecosystem

    var workers: WorkerServiceProtocol = WorkerService.shared
    var pages: PagesServiceProtocol = PagesService.shared
    var d1: D1ServiceProtocol = D1Service.shared
    var kv: KVServiceProtocol = KVService.shared
    var r2: R2ServiceProtocol = R2Service.shared
    var hyperdrive: HyperdriveServiceProtocol = HyperdriveService.shared
    var ai: AIServiceProtocol = AIService.shared
    var queues: QueueServiceProtocol = QueueService.shared
    var durableObjects: DurableObjectServiceProtocol = DurableObjectService.shared

    // MARK: - 7. Zero Trust

    var tunnels: TunnelServiceProtocol = TunnelService.shared
    var turnstile: TurnstileServiceProtocol = TurnstileService.shared
    var access: AccessServiceProtocol = AccessService.shared
    var gateway: GatewayServiceProtocol = GatewayService.shared
    var bulkRedirects: BulkRedirectServiceProtocol = BulkRedirectService.shared

    // MARK: - 8. Observability & System

    var analytics: AnalyticsServiceProtocol = AnalyticsService.shared
    var dashboard: DashboardServiceProtocol = DashboardService.shared
    var alerting: AlertingServiceProtocol = AlertingService.shared
    var auditLog: AuditLogServiceProtocol = AuditLogService.shared
    var status: CloudflareStatusServiceProtocol = CloudflareStatusService.shared

    // MARK: - 9. Diagnostic Tools

    var cfTrace: CFTraceServiceProtocol = CFTraceService.shared
    var dnsDig: DNSDigServiceProtocol = DNSDigService.shared
    var propagation: DNSPropagationServiceProtocol = DNSPropagationService.shared
    var ipLookup: IPLookupServiceProtocol = IPLookupService.shared
    var certInspect: CertInspectServiceProtocol = CertInspectService.shared
    var whois: WhoisServiceProtocol = WhoisService.shared
    var edgeLatency: EdgeLatencyServiceProtocol = EdgeLatencyService.shared
    var ipRanges: CFIpRangesServiceProtocol = CFIpRangesService.shared
    var devTools: DevToolsServiceProtocol = DevToolsService.shared
    var httpHeaderInspector: HTTPHeaderInspectorServiceProtocol = HTTPHeaderInspectorService.shared
    var cidrCalculator: CIDRCalculatorServiceProtocol = CIDRCalculatorService.shared

    init() {}
}
