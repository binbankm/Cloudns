import Foundation
import Combine
import SwiftUI

@MainActor
class CustomCertificatesViewModel: ObservableObject {
    @Published var certificates: [CustomCertificate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchCertificates(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.certificates = try await apiClient.fetchCustomCertificates(zoneId: zoneId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func uploadCertificate(zoneId: String, certificate: String, privateKey: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.uploadCustomCertificate(zoneId: zoneId, certificate: certificate, privateKey: privateKey)
            await fetchCertificates(zoneId: zoneId)
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
}
