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
    
    init() {
        // Pre-fill if they exist (for convenience during development, though usually you don't read them out to text fields)
        if let savedEmail = KeychainHelper.standard.readString(service: CloudflareAPIClient.shared.serviceName, account: "email") {
            self.email = savedEmail
        }
        if let savedKey = KeychainHelper.standard.readString(service: CloudflareAPIClient.shared.serviceName, account: "apiKey") {
            self.apiKey = savedKey
        }
    }
    
    func login() async {
        errorMessage = nil
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty || trimmedKey.isEmpty {
            errorMessage = "Please enter both Email and Global API Key."
            return
        }
        
        isLoading = true
        
        // Temporarily save to Keychain so the API client can use them for the test request
        KeychainHelper.standard.saveString(trimmedEmail, service: CloudflareAPIClient.shared.serviceName, account: "email")
        KeychainHelper.standard.saveString(trimmedKey, service: CloudflareAPIClient.shared.serviceName, account: "apiKey")
        
        do {
            // Validate credentials by attempting to fetch zones
            _ = try await CloudflareAPIClient.shared.getZones(page: 1, perPage: 1)
            
            // If successful, update state
            isLoggedIn = true
        } catch {
            // If failed, remove from keychain and show error
            KeychainHelper.standard.delete(service: CloudflareAPIClient.shared.serviceName, account: "email")
            KeychainHelper.standard.delete(service: CloudflareAPIClient.shared.serviceName, account: "apiKey")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        KeychainHelper.standard.delete(service: CloudflareAPIClient.shared.serviceName, account: "email")
        KeychainHelper.standard.delete(service: CloudflareAPIClient.shared.serviceName, account: "apiKey")
        email = ""
        apiKey = ""
        isLoggedIn = false
    }
}
