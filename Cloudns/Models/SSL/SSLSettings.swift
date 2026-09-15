import Foundation

// MARK: - SSL / TLS Configuration Models (Codable, Sendable, Equatable)

public struct HSTSSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var maxAge: Int
    public var includeSubdomains: Bool
    public var nosniff: Bool
    public var preload: Bool

    public init(
        enabled: Bool = false,
        maxAge: Int = 0,
        includeSubdomains: Bool = false,
        nosniff: Bool = false,
        preload: Bool = false
    ) {
        self.enabled = enabled
        self.maxAge = maxAge
        self.includeSubdomains = includeSubdomains
        self.nosniff = nosniff
        self.preload = preload
    }
}

public struct SSLSettings: Codable, Equatable, Sendable {
    public var sslMode: String
    public var alwaysUseHTTPS: Bool
    public var automaticHTTPSRewrites: Bool
    public var minTLSVersion: String
    public var tls13: Bool
    public var opportunisticEncryption: Bool
    public var opportunisticOnion: Bool
    public var hsts: HSTSSettings

    public init(
        sslMode: String = "off",
        alwaysUseHTTPS: Bool = false,
        automaticHTTPSRewrites: Bool = false,
        minTLSVersion: String = "1.0",
        tls13: Bool = false,
        opportunisticEncryption: Bool = false,
        opportunisticOnion: Bool = false,
        hsts: HSTSSettings = HSTSSettings()
    ) {
        self.sslMode = sslMode
        self.alwaysUseHTTPS = alwaysUseHTTPS
        self.automaticHTTPSRewrites = automaticHTTPSRewrites
        self.minTLSVersion = minTLSVersion
        self.tls13 = tls13
        self.opportunisticEncryption = opportunisticEncryption
        self.opportunisticOnion = opportunisticOnion
        self.hsts = hsts
    }
}
