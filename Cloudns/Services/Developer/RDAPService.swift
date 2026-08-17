import Foundation

/// 统一的 RDAP / WHOIS 查询领域服务
public actor RDAPService {
    public static let shared = RDAPService()
    private let session = URLSession.shared
    
    public func lookup(domain: String) async throws -> WhoisInfo {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .split(separator: "/").first.map(String.init) ?? domain
        
        let name = cleanDomain.lowercased()
        guard name.contains("."), let tld = name.split(separator: ".").last.map(String.init) else {
            throw APIError.invalidURL
        }
        
        let base = try await getRdapBase(forTLD: tld)
        let joined = base.hasSuffix("/") ? "\(base)domain/\(name)" : "\(base)/domain/\(name)"
        guard let url = URL(string: joined) else { throw APIError.invalidURL }
        
        return try await fetchRDAP(url: url, domain: name, isRedirect: false)
    }
    
    private func fetchRDAP(url: URL, domain: String, isRedirect: Bool) async throws -> WhoisInfo {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if http.statusCode == 404 { throw APIError.cloudflareError("Domain not found or no public RDAP information.") }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.cloudflareError("RDAP server responded with status \(http.statusCode)")
        }
        
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw APIError.decodingError(URLError(.cannotParseResponse))
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
            throw APIError.decodingError(URLError(.cannotParseResponse))
        }
        for service in services where service.count >= 2 {
            guard let tlds = service[0] as? [String], let urls = service[1] as? [String] else { continue }
            if tlds.contains(tld), let base = urls.first(where: { $0.hasPrefix("https://") }) ?? urls.first {
                return base
            }
        }
        return "https://rdap.org/domain/"
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
