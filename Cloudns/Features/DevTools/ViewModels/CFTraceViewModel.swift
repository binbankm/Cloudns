import Foundation
import SwiftUI
import Combine

@MainActor
final class CFTraceViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    private let devToolsService: DevToolsServiceProtocol
    
    // MARK: - Published Properties
    @Published var host: String = "www.cloudflare.com"
    @Published var traceFields: [HTTPHeaderItem] = []
    
    // MARK: - Lifecycle / Init
    init(devToolsService: DevToolsServiceProtocol = DevToolsService.shared) {
        self.devToolsService = devToolsService
        super.init()
    }
    
    var coloCode: String? {
        traceFields.first(where: { $0.key == "colo" })?.value
    }
    
    var clientIp: String? {
        traceFields.first(where: { $0.key == "ip" })?.value
    }
    
    var locCountry: String? {
        traceFields.first(where: { $0.key == "loc" })?.value
    }
    
    var warpStatus: String? {
        traceFields.first(where: { $0.key == "warp" })?.value
    }
    
    // MARK: - Public Methods
    func queryTrace() async {
        await executeLoadingTask {
            self.traceFields = try await self.devToolsService.getCFTrace(host: self.host)
        }
    }
}
