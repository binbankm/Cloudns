import Foundation

// MARK: - Cloudflare Tunnel (Zero Trust) Models

public struct CFTunnel: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let status: String?
    public let createdAt: String?
    public let deletedAt: String?
    public let tunnelType: String?
    public let remoteConfig: Bool?
    public let connections: [TunnelConnection]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, status
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case tunnelType = "tunnel_type"
        case remoteConfig = "remote_config"
        case connections
    }
    
    public var isHealthy: Bool {
        status?.lowercased() == "healthy" || status?.lowercased() == "active"
    }
    
    public init(id: String, name: String, status: String? = "healthy", createdAt: String? = "2024-01-01T00:00:00Z", connections: [TunnelConnection]? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.createdAt = createdAt
        self.deletedAt = nil
        self.tunnelType = "cfd_tunnel"
        self.remoteConfig = true
        self.connections = connections
    }
    
    public static let placeholders: [CFTunnel] = (0..<5).map { idx in
        CFTunnel(id: "tunnel-uuid-\(idx + 1)-abcd", name: "edge-gateway-\(idx + 1)", status: "healthy")
    }
}

public struct TunnelConnection: Codable, Identifiable, Equatable {
    public var id: String { clientId ?? UUID().uuidString }
    public let clientId: String?
    public let version: String?
    public let arch: String?
    public let originIp: String?
    public let coloName: String?
    public let isPendingReconnect: Bool?
    public let openedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case version, arch
        case originIp = "origin_ip"
        case coloName = "colo_name"
        case isPendingReconnect = "is_pending_reconnect"
        case openedAt = "opened_at"
    }
}

public struct TunnelIngressRule: Codable, Identifiable, Equatable {
    public var id: String { "\(hostname ?? "")-\(path ?? "")-\(service ?? "")" }
    public let hostname: String?
    public let path: String?
    public let service: String?
    
    public init(hostname: String?, path: String?, service: String?) {
        self.hostname = hostname
        self.path = path
        self.service = service
    }
}
