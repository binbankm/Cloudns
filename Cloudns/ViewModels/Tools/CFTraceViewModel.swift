import Foundation
import SwiftUI
import Combine

@MainActor
final class CFTraceViewModel: BaseLoadableViewModel {
    private let devToolsService: DevToolsServiceProtocol
    
    @Published var host: String = "www.cloudflare.com"
    @Published var traceFields: [HTTPHeaderItem] = []
    
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
    
    func queryTrace() async {
        await executeLoadingTask {
            self.traceFields = try await self.devToolsService.getCFTrace(host: self.host)
        }
    }
}
