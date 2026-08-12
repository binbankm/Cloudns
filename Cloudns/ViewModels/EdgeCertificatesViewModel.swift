import Foundation
import SwiftUI
import Combine

@MainActor
class EdgeCertificatesViewModel: ObservableObject {
    @Published var certificates: [EdgeCertificateModel] = []
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchCertificates(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let packs = try await apiClient.fetchCertificatePacks(zoneId: zoneId)
            
            var customCerts: [CustomCertificate] = []
            do {
                customCerts = try await apiClient.fetchCustomCertificates(zoneId: zoneId)
            } catch {
                print("Notice: Custom certificates fetch failed (possibly due to plan restrictions): \(error.localizedDescription)")
            }
            
            var unifiedCerts: [EdgeCertificateModel] = []
            
            // Map certificate packs (Universal & Advanced)
            for pack in packs {
                if let certs = pack.certificates, let first = certs.first {
                    unifiedCerts.append(EdgeCertificateModel(
                        id: pack.id,
                        type: pack.type,
                        hosts: first.hosts,
                        issuer: first.issuer,
                        status: pack.status,
                        expiresOn: first.expires_on,
                        signature: first.signature
                    ))
                } else {
                    unifiedCerts.append(EdgeCertificateModel(
                        id: pack.id,
                        type: pack.type,
                        hosts: pack.hosts,
                        issuer: "Cloudflare",
                        status: pack.status,
                        expiresOn: "N/A",
                        signature: "N/A"
                    ))
                }
            }
            
            // Map Custom Certificates
            for cert in customCerts {
                unifiedCerts.append(EdgeCertificateModel(
                    id: cert.id,
                    type: "custom",
                    hosts: cert.hosts,
                    issuer: cert.issuer,
                    status: cert.status,
                    expiresOn: cert.expires_on,
                    signature: cert.signature
                ))
            }
            
            self.certificates = unifiedCerts.sorted(by: { $0.type > $1.type }) // Group by type
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
        }
        
        isLoading = false
    }
}
