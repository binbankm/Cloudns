import Foundation

// MARK: - IP & ASN Lookup Models

public struct IPLookupResult: Equatable, Sendable {
    public let query: String
    public let ip: String
    public let asn: String?
    public let org: String?
    public let country: String?
    public let countryCode: String?
    public let city: String?
    public let region: String?
    public let timezone: String?
    public let latitude: Double?
    public let longitude: Double?
    public let isCloudflareAnycast: Bool
    public let cloudProvider: String?
    
    public var countryFlag: String {
        guard let code = countryCode?.uppercased(), code.count == 2 else { return "🌐" }
        return code.unicodeScalars.compactMap {
            UnicodeScalar(127397 + $0.value)
        }.map { String($0) }.joined()
    }
    
    public init(
        query: String,
        ip: String,
        asn: String? = nil,
        org: String? = nil,
        country: String? = nil,
        countryCode: String? = nil,
        city: String? = nil,
        region: String? = nil,
        timezone: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isCloudflareAnycast: Bool = false,
        cloudProvider: String? = nil
    ) {
        self.query = query
        self.ip = ip
        self.asn = asn
        self.org = org
        self.country = country
        self.countryCode = countryCode
        self.city = city
        self.region = region
        self.timezone = timezone
        self.latitude = latitude
        self.longitude = longitude
        self.isCloudflareAnycast = isCloudflareAnycast
        self.cloudProvider = cloudProvider
    }
}
