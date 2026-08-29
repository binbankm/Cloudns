import Foundation
import SwiftUI
import Combine

@MainActor
final class LoginViewModel: BaseLoadableViewModel {
    @Published var email: String = ""
    @Published var apiKey: String = ""
    
    @AppStorage(AppStorageKey.isLoggedIn) var isLoggedIn: Bool = false
    
    private let authService: AuthServiceProtocol
    
    public init(authService: AuthServiceProtocol = AuthService.shared) {
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
            self.errorMessage = APIError.formatCloudflareError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func logout() {
        AccountManager.shared.logoutAll()
        email = ""
        apiKey = ""
    }
}
