import Combine
import Foundation

// MARK: - Login ViewModel (AGENTS.md Pure MVVM & State Machine)

@MainActor
final class LoginViewModel: ObservableObject {
    // MARK: - Form Inputs

    @Published var email: String = "" {
        didSet { clearErrorOnEdit() }
    }

    @Published var apiKey: String = "" {
        didSet { clearErrorOnEdit() }
    }

    @Published var accountName: String = ""
    @Published var showGuideSheet: Bool = false

    // MARK: - UI State Machine

    @Published private(set) var state: ViewState<CloudflareAccount> = .idle
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let accountManager: AccountManager

    init(
        authService: AuthServiceProtocol = ServicesContainer.shared.auth,
        accountManager: AccountManager = AccountManager.shared
    ) {
        self.authService = authService
        self.accountManager = accountManager
    }

    // MARK: - Validation

    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    var isApiKeyValid: Bool {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanKey.count == 37 else { return false }
        return cleanKey.allSatisfy(\.isHexDigit)
    }

    var canSubmit: Bool {
        isEmailValid && isApiKeyValid && !state.isLoading
    }

    // MARK: - Actions

    func login() async {
        guard canSubmit else { return }

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        state = .loading
        errorMessage = nil

        do {
            // 1. Verify credentials by querying Cloudflare zones
            let zones = try await authService.verifyCredentials(email: cleanEmail, apiKey: cleanKey)

            // 2. Query official accounts to retrieve the real account name set by user in Cloudflare
            let accounts = try? await authService.getAccounts(email: cleanEmail, apiKey: cleanKey)
            let user = try? await authService.getUserDetails(email: cleanEmail, apiKey: cleanKey)

            // 3. Resolve display name in order of fidelity:
            // Custom input -> Cloudflare Account name -> Zone Account name -> User profile name -> Email prefix
            let trimmedCustom = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedName: String
            if !trimmedCustom.isEmpty {
                resolvedName = trimmedCustom
            } else if let officialName = accounts?.first(where: { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })?.name {
                resolvedName = officialName
            } else if let zoneAccountName = zones.first?.account?.name, !zoneAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                resolvedName = zoneAccountName
            } else if let user, user.displayName != cleanEmail && !user.displayName.isEmpty {
                resolvedName = user.displayName
            } else {
                let prefix = cleanEmail.components(separatedBy: "@").first ?? cleanEmail
                resolvedName = prefix.isEmpty ? cleanEmail : prefix
            }

            // 4. Save credentials securely to Keychain & persist account metadata
            let account = accountManager.saveAccount(
                name: resolvedName,
                email: cleanEmail,
                apiKey: cleanKey
            )

            state = .loaded(account)
        } catch {
            let humaneMessage = resolveHumaneErrorMessage(for: error)
            errorMessage = humaneMessage
            state = .error(message: humaneMessage)
        }
    }

    func setApiKey(_ key: String) {
        apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private Helpers

    private func clearErrorOnEdit() {
        if errorMessage != nil {
            errorMessage = nil
            if case .error = state {
                state = .idle
            }
        }
    }

    private func resolveHumaneErrorMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .timedOut:
                return "Network offline. Please verify connection and retry."
            default:
                return "Network request interrupted. Please try again."
            }
        }

        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized, .cloudflareError:
                return "Invalid credentials. Please check your email and Global API Key."
            case .networkError:
                return "Network offline. Please verify connection and retry."
            default:
                break
            }
        }

        let message = error.localizedDescription
        if message.contains("401") || message.contains("10000") || message.localizedCaseInsensitiveContains("unauthorized") {
            return "Invalid credentials. Please check your email and Global API Key."
        }

        return "Verification failed. Please check credentials or network."
    }
}
