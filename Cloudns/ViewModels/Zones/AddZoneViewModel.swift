import Combine
import Foundation

// MARK: - AddZoneViewModel (AGENTS.md MVVM & Concurrency)

@MainActor
final class AddZoneViewModel: ObservableObject {
    @Published var domainName: String = ""
    @Published var jumpStart: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let zoneService: ZoneServiceProtocol
    private let authService: AuthServiceProtocol

    init(
        zoneService: ZoneServiceProtocol = ZoneService.shared,
        authService: AuthServiceProtocol = AuthService.shared
    ) {
        self.zoneService = zoneService
        self.authService = authService
    }

    /// Normalizes and validates domain input format
    func normalizedDomain() -> String? {
        var raw = domainName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if raw.hasPrefix("https://") {
            raw = String(raw.dropFirst(8))
        } else if raw.hasPrefix("http://") {
            raw = String(raw.dropFirst(7))
        }

        // Strip trailing slash or path components
        if let slashIndex = raw.firstIndex(of: "/") {
            raw = String(raw[..<slashIndex])
        }

        // Strip port if present
        if let colonIndex = raw.firstIndex(of: ":") {
            raw = String(raw[..<colonIndex])
        }

        // Basic host validation: contains dot, at least 3 chars, no spaces
        guard raw.count >= 3, raw.contains("."), !raw.contains(" ") else {
            return nil
        }

        return raw
    }

    var canSubmit: Bool {
        normalizedDomain() != nil && !isLoading
    }

    /// Submits domain creation request to Cloudflare
    func createZone() async throws -> Zone {
        guard let validDomain = normalizedDomain() else {
            let errorMsg = String(localized: "Enter a valid apex domain (e.g. example.com)")
            errorMessage = errorMsg
            throw APIError.cloudflareError(errorMsg)
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Retrieve official Cloudflare account id
            let accounts = try await authService.getAccounts()
            guard let accountId = accounts.first?.id, !accountId.isEmpty else {
                let errorMsg = String(localized: "Cloudflare account ID not found")
                errorMessage = errorMsg
                throw APIError.cloudflareError(errorMsg)
            }

            let newZone = try await zoneService.createZone(
                name: validDomain,
                accountId: accountId,
                jumpStart: jumpStart
            )

            GentleHaptics.light()
            return newZone
        } catch is CancellationError {
            // Quietly restore without error banner per AGENTS.md 9.2
            throw CancellationError()
        } catch {
            let userFriendlyMsg = (error as? APIError)?.localizedDescription ?? error.localizedDescription
            errorMessage = userFriendlyMsg
            GentleHaptics.warning()
            throw error
        }
    }
}
