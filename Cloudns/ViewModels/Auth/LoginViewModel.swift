import Foundation
import SwiftUI
import Combine

@MainActor
class LoginViewModel: BaseLoadableViewModel {
    @Published var email: String = ""
    @Published var apiKey: String = ""
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    private let zoneService: ZoneServiceProtocol
    
    public init(zoneService: ZoneServiceProtocol = ZoneService.shared) {
        self.zoneService = zoneService
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
        
        // Save temporarily to validate
        let previousActive = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail)
        UserDefaults.standard.set(trimmedEmail, forKey: AppStorageKey.activeAccountEmail)
        KeychainHelper.standard.saveString(trimmedKey, service: AppStorageKey.keychainService, account: trimmedEmail)
        
        do {
            // Validate credentials by attempting to fetch zones
            _ = try await zoneService.getZones(page: 1, perPage: 1, name: nil, status: nil)
            
            // If successful, permanently add to AccountManager
            AccountManager.shared.addAccount(email: trimmedEmail, apiKey: trimmedKey)
            hasFetchedData = true
            onSuccess?()
        } catch {
            // If failed, remove from keychain and rollback active email
            KeychainHelper.standard.delete(service: AppStorageKey.keychainService, account: trimmedEmail)
            if let prev = previousActive {
                UserDefaults.standard.set(prev, forKey: AppStorageKey.activeAccountEmail)
            } else {
                UserDefaults.standard.removeObject(forKey: AppStorageKey.activeAccountEmail)
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
