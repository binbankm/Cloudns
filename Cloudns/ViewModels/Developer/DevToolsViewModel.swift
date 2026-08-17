import Foundation
import SwiftUI
import Combine

@MainActor
class DevToolsViewModel: BaseLoadableViewModel {
    private let apiClient = CloudflareAPIClient.shared
    
    // DNS Dig
    @Published var domainInput = ""
    @Published var selectedRecordType = "A"
    @Published var dnsResult: DNSLookupResult?
    @Published var isDnsLoading = false
    @Published var dnsError: String?
    
    let recordTypes = ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "SRV", "CAA", "HTTPS", "PTR", "DNSKEY", "DS", "TLSA"]
    
    // HTTP Inspector
    @Published var httpUrlInput = ""
    @Published var httpResult: HTTPInspectionResult?
    @Published var isHttpLoading = false
    @Published var httpError: String?
    
    func queryDNS() async {
        let target = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isDnsLoading = true
        dnsError = nil
        dnsResult = nil
        
        do {
            let result = try await apiClient.performDNSLookup(domain: target, type: selectedRecordType)
            self.dnsResult = result
        } catch {
            self.dnsError = error.localizedDescription
        }
        
        isDnsLoading = false
    }
    
    func inspectHTTP() async {
        let target = httpUrlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isHttpLoading = true
        httpError = nil
        httpResult = nil
        
        do {
            let result = try await apiClient.inspectHTTPHeaders(urlString: target)
            self.httpResult = result
        } catch {
            self.httpError = error.localizedDescription
        }
        
        isHttpLoading = false
    }
}
