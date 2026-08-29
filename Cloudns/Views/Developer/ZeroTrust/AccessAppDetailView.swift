import SwiftUI

// MARK: - AccessAppDetailView

struct AccessAppDetailView: View {
    let accountId: String
    let app: AccessApp
    @State private var policies: [AccessPolicy] = []
    @State private var isLoadingPolicies = false
    @State private var errorMessage: String?
    
    private let accessService = AccessService.shared
    
    var body: some View {
        List {
            Section(header: Text("Application Details")) {
                LabeledContent("Name", value: app.name)
                
                LabeledContent("Domain", value: app.domain)
                
                if let type = app.type {
                    LabeledContent("Type") {
                        HIGBadge(.custom(color: .purple, text: type.capitalized), isCompact: true)
                    }
                }
                
                if let aud = app.aud {
                    LabeledContent("Audience Tag (AUD)") {
                        Text(aud)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("Access Policies (\(policies.count))")) {
                if isLoadingPolicies && policies.isEmpty {
                    ForEach(AccessPolicy.placeholders) { placeholder in
                        policyRow(placeholder)
                    }
                    .redacted(reason: .placeholder)
                } else if let err = errorMessage, policies.isEmpty {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if policies.isEmpty {
                    Text("No policies assigned to this application.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(policies) { p in
                        policyRow(p)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchPolicies()
        }
    }
    
    @ViewBuilder
    private func policyRow(_ p: AccessPolicy) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(p.name)
                    .font(.body)
                Text("Decision: \(p.decision.capitalized)")
                    .font(.caption2)
                    .foregroundStyle(p.decision.lowercased() == "allow" ? .green : .orange)
            }
            Spacer()
            if let prec = p.precedence {
                Text("#\(prec)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func fetchPolicies() async {
        isLoadingPolicies = true
        errorMessage = nil
        do {
            var targetId = self.accountId
            if targetId.isEmpty {
                let accounts = try? await ZoneService.shared.getAccounts()
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                targetId = accounts?.first(where: { $0.name == activeEmail || $0.id == activeEmail })?.id ?? accounts?.first?.id ?? ""
            }
            guard !targetId.isEmpty else {
                self.policies = []
                self.isLoadingPolicies = false
                return
            }
            self.policies = try await AccessService.shared.listAccessPolicies(accountId: targetId, appId: app.id)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoadingPolicies = false
    }
}
