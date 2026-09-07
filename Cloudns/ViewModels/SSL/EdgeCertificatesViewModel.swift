import Foundation
import SwiftUI
import Combine

@MainActor
class EdgeCertificatesViewModel: BaseLoadableViewModel {
    @Published var certificates: [EdgeCertificateModel] = []
    @Published var isUniversalSSLEnabled: Bool = true
    
    private let certService: CertificateServiceProtocol
    
    init(certService: CertificateServiceProtocol = CertificateService.shared) {
        self.certService = certService
        super.init()
    }
    
    func fetchCertificates(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchPacks = certService.getCertificates(zoneId: zoneId)
            async let fetchUni = (try? certService.getUniversalSSLSetting(zoneId: zoneId)) ?? true
            let (packs, uniEnabled) = try await (fetchPacks, fetchUni)
            self.isUniversalSSLEnabled = uniEnabled
            
            var customCerts: [CustomCertificate] = []
            do {
                customCerts = try await certService.fetchCustomCertificates(zoneId: zoneId)
            } catch {
                customCerts = []
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
                    issuer: cert.issuer ?? String(localized: "Custom CA"),
                    status: cert.status ?? "active",
                    expiresOn: cert.expires_on ?? "N/A",
                    signature: cert.signature ?? String(localized: "Custom")
                ))
            }
            
            self.certificates = unifiedCerts.sorted(by: { $0.type > $1.type })
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
        }
        
        isLoading = false
    }
    
    func toggleUniversalSSL(zoneId: String, enabled: Bool) async {
        isUniversalSSLEnabled = enabled
        do {
            try await certService.updateUniversalSSL(zoneId: zoneId, enabled: enabled)
            await fetchCertificates(zoneId: zoneId)
        } catch {
            isUniversalSSLEnabled = !enabled
        }
    }
    
    func deleteCertificate(zoneId: String, cert: EdgeCertificateModel) async {
        do {
            if cert.type.lowercased() == "custom" {
                try await certService.deleteCustomCertificate(zoneId: zoneId, certificateId: cert.id)
            } else {
                try await certService.deleteCertificatePack(zoneId: zoneId, packId: cert.id)
            }
            await fetchCertificates(zoneId: zoneId)
        } catch {
        }
    }
}
