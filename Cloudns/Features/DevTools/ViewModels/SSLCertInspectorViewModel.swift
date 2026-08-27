import Foundation
import SwiftUI
import Combine

@MainActor
class SSLCertInspectorViewModel: BaseLoadableViewModel {
    private let devToolsService: DevToolsServiceProtocol
    
    @Published var domainInput: String = ""
    @Published var certDetails: SSLCertDetails?
    
    init(devToolsService: DevToolsServiceProtocol = DevToolsService.shared) {
        self.devToolsService = devToolsService
        super.init()
    }
    
    func inspectCert() async {
        let domain = domainInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !domain.isEmpty else { return }
        certDetails = nil
        
        await executeLoadingTask {
            self.certDetails = try await self.devToolsService.inspectSSLCertificate(domain: domain)
        }
    }
}
