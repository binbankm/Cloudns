import Foundation
import SwiftUI
import Combine

@MainActor
class SSLCertInspectorViewModel: BaseLoadableViewModel {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var domainInput: String = "cloudflare.com"
    @Published var certDetails: SSLCertDetails?
    
    func inspectCert() async {
        let domain = domainInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !domain.isEmpty else { return }
        certDetails = nil
        
        await executeLoadingTask {
            self.certDetails = try await self.apiClient.inspectSSLCertificate(domain: domain)
        }
    }
}
