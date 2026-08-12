import Foundation
import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var apiKey: String = ""
    @Published var errorMessage: String? = nil
    
    @Published var isLoading: Bool = false
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    init() {}
    
    func login(onSuccess: (() -> Void)? = nil) async {
        errorMessage = nil
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty || trimmedKey.isEmpty {
            errorMessage = "Please enter both Email and Global API Key."
            return
        }
        
        isLoading = true
        
        // Save temporarily to validate
        let previousActive = UserDefaults.standard.string(forKey: "activeAccountEmail")
        UserDefaults.standard.set(trimmedEmail, forKey: "activeAccountEmail")
        KeychainHelper.standard.saveString(trimmedKey, service: CloudflareAPIClient.shared.serviceName, account: trimmedEmail)
        
        do {
            // Validate credentials by attempting to fetch zones
            _ = try await CloudflareAPIClient.shared.getZones(page: 1, perPage: 1)
            
            // If successful, permanently add to AccountManager
            AccountManager.shared.addAccount(email: trimmedEmail, apiKey: trimmedKey)
            onSuccess?()
        } catch {
            // If failed, remove from keychain and rollback active email
            KeychainHelper.standard.delete(service: CloudflareAPIClient.shared.serviceName, account: trimmedEmail)
            if let prev = previousActive {
                UserDefaults.standard.set(prev, forKey: "activeAccountEmail")
            } else {
                UserDefaults.standard.removeObject(forKey: "activeAccountEmail")
            }
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        AccountManager.shared.logoutAll()
        email = ""
        apiKey = ""
    }
}
