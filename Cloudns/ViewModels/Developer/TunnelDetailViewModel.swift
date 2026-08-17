import Foundation
import SwiftUI
import Combine

@MainActor
class TunnelDetailViewModel: BaseLoadableViewModel {
    let accountId: String
    let tunnel: CFTunnel
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var ingressRules: [TunnelIngressRule] = []
    @Published var token: String?
    @Published var isDeleting = false
    
    init(accountId: String, tunnel: CFTunnel) {
        self.accountId = accountId
        self.tunnel = tunnel
        super.init()
    }
    
    func fetchConfiguration() async {
        await executeLoadingTask {
            async let fetchConfig = self.apiClient.getTunnelConfigurations(accountId: self.accountId, tunnelId: self.tunnel.id)
            async let fetchTok = self.apiClient.getTunnelToken(accountId: self.accountId, tunnelId: self.tunnel.id)
            let (rules, tok) = try await (fetchConfig, fetchTok)
            self.ingressRules = rules
            self.token = tok
        }
    }
    
    func addIngressRule(hostname: String, path: String?, service: String) async -> Bool {
        var updated = ingressRules
        let newRule = TunnelIngressRule(hostname: hostname.isEmpty ? nil : hostname, path: path?.isEmpty == true ? nil : path, service: service)
        if let last = updated.last, last.hostname == nil && last.path == nil {
            updated.insert(newRule, at: updated.count - 1)
        } else {
            updated.append(newRule)
            if !updated.contains(where: { $0.hostname == nil && $0.path == nil }) {
                updated.append(TunnelIngressRule(hostname: nil, path: nil, service: "http_status:404"))
            }
        }
        
        do {
            try await apiClient.updateTunnelConfigurations(accountId: accountId, tunnelId: tunnel.id, ingressRules: updated)
            self.ingressRules = updated
            ToastManager.shared.showSuccess("Ingress Rule Added", message: hostname)
            return true
        } catch {
            ToastManager.shared.showError("Save Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteIngressRule(at index: Int) async {
        var updated = ingressRules
        guard index < updated.count else { return }
        updated.remove(at: index)
        if updated.isEmpty || !updated.contains(where: { $0.hostname == nil && $0.path == nil }) {
            updated.append(TunnelIngressRule(hostname: nil, path: nil, service: "http_status:404"))
        }
        do {
            try await apiClient.updateTunnelConfigurations(accountId: accountId, tunnelId: tunnel.id, ingressRules: updated)
            self.ingressRules = updated
            ToastManager.shared.showSuccess("Ingress Rule Deleted", message: "")
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func deleteTunnel() async -> Bool {
        isDeleting = true
        do {
            try await apiClient.deleteTunnel(accountId: accountId, tunnelId: tunnel.id)
            ToastManager.shared.showSuccess("Tunnel Deleted", message: tunnel.name)
            isDeleting = false
            return true
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            isDeleting = false
            return false
        }
    }
}
