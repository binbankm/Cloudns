import Foundation
import SwiftUI
import Combine

@MainActor
final class HTTPHeaderInspectorViewModel: BaseLoadableViewModel {
    @Published var httpUrlInput = ""
    @Published var httpMethod = "HEAD"
    @Published var httpResult: HTTPInspectionResult?
    @Published var isHttpLoading = false
    @Published var httpError: String?
    
    let httpMethods = ["HEAD", "GET", "OPTIONS"]
    
    private let httpService: HTTPHeaderInspectorServiceProtocol
    
    init(httpService: HTTPHeaderInspectorServiceProtocol = HTTPHeaderInspectorService.shared) {
        self.httpService = httpService
        super.init()
    }
    
    func inspectHTTPHeaders() async {
        let clean = httpUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        isHttpLoading = true
        httpError = nil
        httpResult = nil
        
        do {
            let res = try await httpService.inspectHTTPHeaders(urlString: clean, method: httpMethod)
            self.httpResult = res
            self.hasFetchedData = true
            HIGFeedback.success()
        } catch {
            self.httpError = error.localizedDescription
            HIGFeedback.error()
        }
        isHttpLoading = false
    }
    
    func inspectHTTP() async {
        await inspectHTTPHeaders()
    }
}
