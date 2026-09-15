import Foundation

// MARK: - Network Settings Model (Codable, Sendable, Equatable)

public struct NetworkSettings: Codable, Equatable, Sendable {
    public var ipv6: Bool
    public var websockets: Bool
    public var http2: Bool
    public var http3: Bool
    public var ipGeolocation: Bool
    public var originMaxHttpVersion: String
    public var securityHeader: HSTSSettings?

    public init(
        ipv6: Bool = false,
        websockets: Bool = false,
        http2: Bool = false,
        http3: Bool = false,
        ipGeolocation: Bool = false,
        originMaxHttpVersion: String = "2",
        securityHeader: HSTSSettings? = nil
    ) {
        self.ipv6 = ipv6
        self.websockets = websockets
        self.http2 = http2
        self.http3 = http3
        self.ipGeolocation = ipGeolocation
        self.originMaxHttpVersion = originMaxHttpVersion
        self.securityHeader = securityHeader
    }
}
