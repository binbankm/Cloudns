import Foundation
import SwiftUI
import Combine

@MainActor
final class HTTPHeaderInspectorViewModel: BaseLoadableViewModel {
    @Published var urlString: String = "https://www.cloudflare.com"
    @Published var method: String = "HEAD"
    @Published var result: HTTPInspectionResult?
    
    private let httpService: HTTPHeaderInspectorServiceProtocol
    
    init(httpService: HTTPHeaderInspectorServiceProtocol = HTTPHeaderInspectorService.shared) {
        self.httpService = httpService
        super.init()
    }
    
    func inspect() async {
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        await executeLoadingTask {
            let res = try await self.httpService.inspectHTTPHeaders(urlString: clean, method: self.method)
            self.result = res
            self.hasFetchedData = true
        }
    }
}
