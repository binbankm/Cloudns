import Foundation
import SwiftUI
import Combine

@MainActor
final class LoginViewModel: BaseLoadableViewModel {
    @Published var email: String = ""
    @Published var apiKey: String = ""
    
    @AppStorage(AppStorageKey.isLoggedIn) var isLoggedIn: Bool = false
    
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
        
        do {
            // Validate credentials by attempting to fetch zones with explicit credentials
            let request = try AuthenticatedRequestFactory.shared.createExplicitAuthenticatedRequest(
                email: trimmedEmail,
                apiKey: trimmedKey,
                path: "zones",
                queryItems: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "per_page", value: "1")
                ]
            )
            let (_, _): ([Zone]?, ResultInfo?) = try await HTTPNetworkClient.shared.performRequest(request)
            
            // If validated successfully, permanently add to AccountManager
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
