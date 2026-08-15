import SwiftUI
import Combine
import Foundation

// MARK: - WHOIS Info Model

public struct WhoisInfo: Identifiable, Sendable {
    public nonisolated var id: String { domain }
    public let domain: String
    public let statuses: [String]
    public let registrar: String?
    public let created: Date?
    public let updated: Date?
    public let expires: Date?
    public let nameservers: [String]
    
    public nonisolated init(
        domain: String,
        statuses: [String] = [],
        registrar: String? = nil,
        created: Date? = nil,
        updated: Date? = nil,
        expires: Date? = nil,
        nameservers: [String] = []
    ) {
        self.domain = domain
        self.statuses = statuses
        self.registrar = registrar
        self.created = created
        self.updated = updated
        self.expires = expires
        self.nameservers = nameservers
    }
}

// MARK: - RDAP Service

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
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: str) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: str)
    }
}

// MARK: - WHOIS Tool View

@MainActor
class WhoisViewModel: ObservableObject {
    @Published var domainInput = "cloudflare.com"
    @Published var info: WhoisInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func performLookup() async {
        let trimmed = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            self.info = try await RDAPService.shared.lookup(domain: trimmed)
        } catch {
            self.errorMessage = error.localizedDescription
            self.info = nil
        }
        
        isLoading = false
    }
}

struct WhoisToolView: View {
    @StateObject private var viewModel = WhoisViewModel()
    
    let presets = ["cloudflare.com", "apple.com", "github.com", "google.com"]
    
    var body: some View {
        List {
            // Section 1: Query Input
            Section(header: Text("WHOIS & RDAP Lookup"), footer: Text("Queries global IANA RDAP directory over encrypted HTTPS (no account needed).")) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .foregroundStyle(.teal)
                    
                    TextField("example.com", text: $viewModel.domainInput)
                        .font(.body.monospacedDigit())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.performLookup() }
                        }
                    
                    if !viewModel.domainInput.isEmpty {
                        Button {
                            viewModel.domainInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        Task { await viewModel.performLookup() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Query")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                }
                
                // Quick Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                viewModel.domainInput = preset
                                Task { await viewModel.performLookup() }
                            } label: {
                                Text(preset)
                                    .font(.caption.monospacedDigit())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Section 2: Results
            if let error = viewModel.errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Lookup Failed", systemImage: "exclamationmark.triangle.fill")
                            .font(.body)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else if let info = viewModel.info {
                Section(header: Text("Registration Information")) {
                    HStack {
                        Text("Domain Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(info.domain)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
                    if let reg = info.registrar {
                        HStack {
                            Text("Registrar")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(reg)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if let created = info.created {
                        HStack {
                            Text("Created Date")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatDate(created))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if let updated = info.updated {
                        HStack {
                            Text("Updated Date")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatDate(updated))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if let expires = info.expires {
                        HStack {
                            Text("Expiration Date")
                                .foregroundStyle(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatDate(expires))
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(.primary)
                                
                                let days = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
                                Text(days > 0 ? "\(days) days remaining" : "Expired")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(days > 30 ? .green : .red)
                            }
                        }
                    }
                }
                
                // Section: Domain Statuses
                if !info.statuses.isEmpty {
                    Section(header: Text("Domain Statuses (\(info.statuses.count))")) {
                        ForEach(info.statuses, id: \.self) { status in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.teal)
                                    .frame(width: 6, height: 6)
                                Text(status)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // Section: Nameservers
                if !info.nameservers.isEmpty {
                    Section(header: Text("Authoritative Nameservers (\(info.nameservers.count))")) {
                        ForEach(info.nameservers, id: \.self) { ns in
                            HStack {
                                Image(systemName: "server.rack")
                                    .font(.caption)
                                    .foregroundStyle(.teal)
                                Text(ns.lowercased())
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.primary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = ns.lowercased()
                                    ToastManager.shared.showCopied("\(ns.lowercased()) copied")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } else if viewModel.isLoading {
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            }
        }
        .navigationTitle("WHOIS")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.info == nil {
                await viewModel.performLookup()
            }
        }
        .toastContainer()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
