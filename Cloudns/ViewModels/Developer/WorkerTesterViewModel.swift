import Foundation
import SwiftUI
import Combine

@MainActor
class WorkerTesterViewModel: BaseLoadableViewModel {
    let scriptName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var targetUrl: String = ""
    @Published var selectedMethod: String = "GET"
    @Published var requestBody: String = ""
    @Published var responseStatusCode: Int?
    @Published var responseStatusText: String?
    @Published var responseDurationMs: Double?
    @Published var responseHeaders: [HTTPHeaderItem] = []
    @Published var responseBody: String?
    @Published var isTesting = false
    
    let methods = ["GET", "POST", "PUT", "PATCH", "DELETE"]
    
    init(scriptName: String, initialRoute: String? = nil) {
        self.scriptName = scriptName
        if let route = initialRoute, !route.isEmpty {
            self.targetUrl = "https://" + route.replacingOccurrences(of: "*", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        } else {
            self.targetUrl = "https://\(scriptName).workers.dev"
        }
        super.init()
    }
    
    func executeDispatch() async {
        let trimmed = targetUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isTesting = true
        errorMessage = nil
        responseStatusCode = nil
        responseStatusText = nil
        responseDurationMs = nil
        responseHeaders = []
        responseBody = nil
        
        do {
            var headers: [String: String] = [:]
            if selectedMethod == "POST" || selectedMethod == "PUT" || selectedMethod == "PATCH" {
                headers["Content-Type"] = "application/json"
            }
            
            let res = try await apiClient.testWorkerDispatch(
                urlString: trimmed,
                httpMethod: selectedMethod,
                headers: headers,
                body: requestBody.isEmpty ? nil : requestBody
            )
            
            self.responseStatusCode = res.statusCode
            self.responseStatusText = res.statusText
            self.responseDurationMs = res.durationMs
            self.responseHeaders = res.headers
            self.responseBody = res.responseBody
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isTesting = false
    }
}
