import Combine
import Foundation

@MainActor
final class LoginViewModel: BaseLoadableViewModel {
    @Published var email: String = ""
    @Published var apiKey: String = ""
    var isLoggedIn: Bool {
        get { AccountManager.shared.isLoggedIn }
        set { AccountManager.shared.isLoggedIn = newValue }
    }

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
        super.init()
    }

    func login(onSuccess: (() -> Void)? = nil) async {
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty || trimmedKey.isEmpty {
            errorMessage = "Please enter both Email and Global API Key."
            return
        }

        isLoading = true

        do {
            _ = try await authService.verifyCredentials(email: trimmedEmail, apiKey: trimmedKey)
            AccountManager.shared.addAccount(email: trimmedEmail, apiKey: trimmedKey)
            hasFetchedData = true
            onSuccess?()
        } catch {
            errorMessage = APIError.formatCloudflareError(error.localizedDescription)
        }

        isLoading = false
    }

    func logout() {
        AccountManager.shared.logoutAll()
        email = ""
        apiKey = ""
    }
}
