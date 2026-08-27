import Foundation
import SwiftUI
import Combine

@MainActor
class SSLCertInspectorViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    private let devToolsService: DevToolsServiceProtocol
    
    // MARK: - Published Properties
    @Published var domainInput: String = ""
    @Published var certDetails: SSLCertDetails?
    
    // MARK: - Lifecycle / Init
    init(devToolsService: DevToolsServiceProtocol = DevToolsService.shared) {
        self.devToolsService = devToolsService
        super.init()
    }
    
    // MARK: - Public Methods
    func inspectCert() async {
        let domain = domainInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !domain.isEmpty else { return }
        certDetails = nil
        
        await executeLoadingTask {
            self.certDetails = try await self.devToolsService.inspectSSLCertificate(domain: domain)
        }
    }
}
