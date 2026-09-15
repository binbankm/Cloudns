import Combine
import Foundation

// MARK: - TTL Option

struct DNSTTLOption: Identifiable, Hashable, Sendable {
    let seconds: Int
    let displayName: String

    var id: Int { seconds }

    static let commonOptions: [DNSTTLOption] = [
        DNSTTLOption(seconds: 1, displayName: String(localized: "Auto")),
        DNSTTLOption(seconds: 60, displayName: String(localized: "1 min")),
        DNSTTLOption(seconds: 120, displayName: String(localized: "2 mins")),
        DNSTTLOption(seconds: 300, displayName: String(localized: "5 mins")),
        DNSTTLOption(seconds: 600, displayName: String(localized: "10 mins")),
        DNSTTLOption(seconds: 900, displayName: String(localized: "15 mins")),
        DNSTTLOption(seconds: 1800, displayName: String(localized: "30 mins")),
        DNSTTLOption(seconds: 3600, displayName: String(localized: "1 hour")),
        DNSTTLOption(seconds: 7200, displayName: String(localized: "2 hours")),
        DNSTTLOption(seconds: 86400, displayName: String(localized: "1 day"))
    ]
}

// MARK: - DNSRecordFormViewModel

@MainActor
final class DNSRecordFormViewModel: ObservableObject {
    // MARK: - Published Form Fields

    @Published var selectedType: DNSRecordType = .a
    @Published var name: String = ""
    @Published var content: String = ""
    @Published var proxied: Bool = true
    @Published var ttl: Int = 1
    @Published var priority: String = "10"
    @Published var comment: String = ""

    // MARK: - Published Submission State

    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Mode & Dependencies

    let zone: Zone
    let existingRecord: DNSRecord?
    private let dnsService: DNSServiceProtocol

    var isEditing: Bool {
        existingRecord != nil
    }

    var requiresPriority: Bool {
        selectedType == .mx || selectedType == .srv
    }

    var supportsProxy: Bool {
        selectedType.isProxiable
    }

    var canSubmit: Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanContent.isEmpty else { return false }

        if requiresPriority {
            guard let prio = Int(priority), prio >= 0 else { return false }
        }

        return !isLoading
    }

    // MARK: - Initializer

    init(
        zone: Zone,
        existingRecord: DNSRecord? = nil,
        dnsService: DNSServiceProtocol = DNSService.shared
    ) {
        self.zone = zone
        self.existingRecord = existingRecord
        self.dnsService = dnsService

        if let record = existingRecord {
            self.selectedType = DNSRecordType(rawValue: record.type.uppercased()) ?? .a
            self.name = record.name
            self.content = record.content ?? ""
            self.proxied = record.proxied ?? false
            self.ttl = record.ttl
            if let prio = record.priority {
                self.priority = "\(prio)"
            }
            self.comment = record.comment ?? ""
        }
    }

    // MARK: - Type Change Handler

    func onTypeChanged(_ newType: DNSRecordType) {
        selectedType = newType
        if !newType.isProxiable {
            proxied = false
        }
        errorMessage = nil
    }

    // MARK: - Form Submission

    func submit() async throws -> DNSRecord {
        guard canSubmit else {
            throw APIError.cloudflareError(String(localized: "Please fill in all required fields."))
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        let prioInt = requiresPriority ? Int(priority) : nil

        let payload = DNSRecordPayload(
            type: selectedType.rawValue,
            name: cleanName,
            content: cleanContent,
            ttl: proxied ? 1 : ttl,
            proxied: supportsProxy ? proxied : false,
            priority: prioInt,
            comment: cleanComment.isEmpty ? nil : cleanComment
        )

        do {
            let savedRecord: DNSRecord
            if let existing = existingRecord {
                savedRecord = try await dnsService.updateDNSRecord(
                    zoneId: zone.id,
                    recordId: existing.id,
                    payload: payload
                )
            } else {
                savedRecord = try await dnsService.createDNSRecord(
                    zoneId: zone.id,
                    payload: payload
                )
            }

            GentleHaptics.success()
            return savedRecord
        } catch {
            let message = resolveHumaneErrorMessage(for: error)
            self.errorMessage = message
            throw error
        }
    }

    private func resolveHumaneErrorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case let .cloudflareError(message):
                return message
            case .networkError:
                return String(localized: "Network connection is unavailable. Please check your network and retry.")
            case .unauthorized:
                return String(localized: "Authentication failed. Please verify your Global API Key.")
            default:
                break
            }
        }
        if let urlError = error as? URLError {
            if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                return String(localized: "Network connection is unavailable. Please check your network and retry.")
            }
        }
        return String(localized: "Operation Failed")
    }
}
