import Foundation

/// RDAP / WHOIS 查询领域服务抽象协议
protocol RDAPServiceProtocol: Sendable {
    func lookup(domain: String) async throws -> WhoisInfo
}

/// 统一的 RDAP / WHOIS 查询领域服务
public actor RDAPService: RDAPServiceProtocol {
    // MARK: - Lifecycle & Dependencies
    public static let shared = RDAPService()
    private let session = URLSession.shared
    
    // MARK: - RDAP & Whois Lookup API
    public func lookup(domain: String) async throws -> WhoisInfo {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .split(separator: "/").first.map(String.init) ?? domain
        
        let name = cleanDomain.lowercased()
        guard name.contains("."), let tld = name.split(separator: ".").last.map(String.init) else {
            throw APIError.invalidURL
        }
        
        // 1. Try RDAP lookup
        do {
            let base = try await getRdapBase(forTLD: tld)
            let joined = base.hasSuffix("/") ? "\(base)domain/\(name)" : "\(base)/domain/\(name)"
            guard let url = URL(string: joined) else { throw APIError.invalidURL }
            
            return try await fetchRDAP(url: url, domain: name, isRedirect: false)
        } catch {
            // 2. Fallback: Try Global rdap.org universal gateway
            if let rdapOrgUrl = URL(string: "https://rdap.org/domain/\(name)") {
                if let info = try? await fetchRDAP(url: rdapOrgUrl, domain: name, isRedirect: true) {
                    return info
                }
            }
            
            // 3. Fallback: Authoritative DNS Discovery (for subdomains like .us.kg or unlisted ccTLDs)
            if let dnsInfo = try? await fallbackDNSLookup(domain: name) {
                return dnsInfo
            }
            
            throw error
        }
    }
    
    private func fetchRDAP(url: URL, domain: String, isRedirect: Bool) async throws -> WhoisInfo {
        // Enforce HTTPS
        var finalUrl = url
        if url.scheme?.lowercased() == "http", var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.scheme = "https"
            if let upgraded = components.url {
                finalUrl = upgraded
            }
        }
        
        var request = URLRequest(url: finalUrl)
        request.timeoutInterval = 10
        request.setValue("application/rdap+json, application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 404 {
            throw APIError.cloudflareError("Domain not found in RDAP registry.")
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.cloudflareError("RDAP registry returned status \(http.statusCode)")
        }
        
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw APIError.decodingError("Unable to parse RDAP payload.")
        }
        
        let parsed = parseRDAP(obj, domain: domain)
        
        // Follow redirect links if expiration is missing and not yet redirected
        if parsed.expires == nil && !isRedirect {
            if let links = obj["links"] as? [[String: Any]],
               let related = links.first(where: { ($0["rel"] as? String) == "related" || ($0["rel"] as? String) == "registrar" }),
               let href = related["href"] as? String,
               let redirectUrl = URL(string: href) {
                if let redirectedParsed = try? await fetchRDAP(url: redirectUrl, domain: domain, isRedirect: true) {
                    return WhoisInfo(
                        domain: parsed.domain,
                        statuses: redirectedParsed.statuses.isEmpty ? parsed.statuses : redirectedParsed.statuses,
                        registrar: redirectedParsed.registrar ?? parsed.registrar,
                        created: redirectedParsed.created ?? parsed.created,
                        updated: redirectedParsed.updated ?? parsed.updated,
                        expires: redirectedParsed.expires ?? parsed.expires,
                        nameservers: redirectedParsed.nameservers.isEmpty ? parsed.nameservers : redirectedParsed.nameservers
                    )
                }
            }
        }
        return parsed
    }
    
    private func getRdapBase(forTLD tld: String) async throws -> String {
        guard let url = URL(string: "https://data.iana.org/rdap/dns.json") else {
            throw APIError.invalidURL
        }
        let (data, _) = try await session.data(from: url)
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let services = obj["services"] as? [[Any]] else {
            throw APIError.decodingError("Unable to parse IANA RDAP bootstrap data.")
        }
        for service in services where service.count >= 2 {
            guard let tlds = service[0] as? [String], let urls = service[1] as? [String] else { continue }
            if tlds.contains(tld) {
                // Prefer HTTPS endpoint
                if let httpsBase = urls.first(where: { $0.hasPrefix("https://") }) {
                    return httpsBase
                }
                if let first = urls.first {
                    return first.replacingOccurrences(of: "http://", with: "https://")
                }
            }
        }
        return "https://rdap.org/domain/"
    }
    
    private func fallbackDNSLookup(domain: String) async throws -> WhoisInfo? {
        guard var comp = URLComponents(string: "https://1.1.1.1/dns-query") else { return nil }
        comp.queryItems = [
            URLQueryItem(name: "name", value: domain),
            URLQueryItem(name: "type", value: "NS")
        ]
        guard let url = comp.url else { return nil }
        
        var req = URLRequest(url: url)
        req.setValue("application/dns-json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 6.0
        
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        
        struct DoHAns: Codable {
            let name: String
            let type: Int
            let data: String
        }
        struct DoHResp: Codable {
            let Status: Int
            let Answer: [DoHAns]?
            let Authority: [DoHAns]?
        }
        
        guard let doh = try? JSONDecoder().decode(DoHResp.self, from: data) else { return nil }
        let answers = (doh.Answer ?? []) + (doh.Authority ?? [])
        let nsRecords = answers.filter { $0.type == 2 }.map {
            $0.data.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        }
        
        guard !nsRecords.isEmpty else { return nil }
        
        var provider = "Authoritative DNS Delegated"
        let lower = nsRecords.joined(separator: " ").lowercased()
        if lower.contains("cloudflare.com") {
            provider = "Cloudflare Managed Authoritative DNS"
        } else if lower.contains("awsdns") {
            provider = "Amazon Route 53"
        } else if lower.contains("googledomains") || lower.contains("google") {
            provider = "Google Cloud DNS"
        } else if lower.contains("dnspod") {
            provider = "Tencent DNSPod"
        } else if lower.contains("alidns") {
            provider = "Alibaba Cloud DNS"
        }
        
        return WhoisInfo(
            domain: domain,
            statuses: ["Active (DNS Delegated)", "Authoritative Zone"],
            registrar: provider,
            created: nil,
            updated: nil,
            expires: nil,
            nameservers: nsRecords
        )
    }
    
    private func parseRDAP(_ obj: [String: Any], domain: String) -> WhoisInfo {
        let statuses = obj["status"] as? [String] ?? []
        let allEvents = extractEvents(from: obj)
        
        func eventDate(_ actionMatch: (String) -> Bool) -> Date? {
            guard let raw = allEvents.first(where: {
                guard let action = ($0["eventAction"] as? String)?.lowercased() else { return false }
                return actionMatch(action)
            })?["eventDate"] as? String else { return nil }
            return isoDate(raw)
        }
        
        let nameservers = (obj["nameservers"] as? [[String: Any]])?.compactMap { $0["ldhName"] as? String } ?? []
        return WhoisInfo(
            domain: (obj["ldhName"] as? String) ?? domain,
            statuses: statuses,
            registrar: extractRegistrarName(obj["entities"]),
            created: eventDate { $0.contains("registration") && !$0.contains("expiration") },
            updated: eventDate { $0.contains("last changed") || $0.contains("update") },
            expires: eventDate { $0.contains("expiration") },
            nameservers: nameservers
        )
    }
    
    private func extractEvents(from node: Any) -> [[String: Any]] {
        var found: [[String: Any]] = []
        if let dict = node as? [String: Any] {
            if let events = dict["events"] as? [[String: Any]] {
                found.append(contentsOf: events)
            }
            if let entities = dict["entities"] as? [[String: Any]] {
                for entity in entities {
                    found.append(contentsOf: extractEvents(from: entity))
                }
            }
        }
        return found
    }
    
    private func extractRegistrarName(_ node: Any?) -> String? {
        guard let entities = node as? [[String: Any]] else { return nil }
        for entity in entities {
            let roles = entity["roles"] as? [String] ?? []
            if roles.contains("registrar") {
                if let vcard = entity["vcardArray"] as? [Any], vcard.count >= 2, let properties = vcard[1] as? [[Any]] {
                    for prop in properties where prop.count >= 4 {
                        if (prop[0] as? String) == "fn", let name = prop[3] as? String {
                            return name
                        }
                    }
                }
                if let handle = entity["handle"] as? String {
                    return handle
                }
            }
        }
        return nil
    }
    
    private func isoDate(_ str: String) -> Date? {
        DateFormatters.parseISO8601(str)
    }
}
