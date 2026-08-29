import Foundation
import SwiftUI
import Combine

@MainActor
final class CertInspectViewModel: BaseLoadableViewModel {
    private let certService: CertInspectServiceProtocol
    
    @Published var domainInput: String = ""
    @Published var certDetails: SSLCertDetails?
    
    init(certService: CertInspectServiceProtocol = CertInspectService.shared) {
        self.certService = certService
        super.init()
    }
    
    func inspectCert() async {
        let domain = domainInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !domain.isEmpty else { return }
        certDetails = nil
        
        await executeLoadingTask {
            self.certDetails = try await self.certService.inspectSSLCertificate(domain: domain)
            self.hasFetchedData = true
        }
    }
}

typealias SSLCertInspectorViewModel = CertInspectViewModel
