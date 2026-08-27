import SwiftUI

// MARK: - AccessAppDetailView

struct AccessAppDetailView: View {
    // MARK: - Properties
    let accountId: String
    let app: AccessApp
    @State private var policies: [AccessPolicy] = []
    @State private var isLoadingPolicies = false
    @State private var errorMessage: String?
    
    private let accessService = AccessService.shared
    
    // MARK: - Body
    var body: some View {
        List {
            Section(header: Text("Application Details")) {
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(app.name)
                        .font(.body.weight(.medium))
                }
                
                HStack {
                    Text("Domain")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(app.domain)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                
                if let type = app.type {
                    HStack {
                        Text("Type")
                            .foregroundStyle(.secondary)
                        Spacer()
                        CloudnsBadge(.custom(color: .purple, text: type.capitalized), isCompact: true)
                    }
                }
                
                if let aud = app.aud {
                    HStack {
                        Text("Audience Tag (AUD)")
                            .foregroundStyle(.secondary)
                        Spacer()
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
                    .skeletonLoading(true)
                } else if let err = errorMessage, policies.isEmpty {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(CloudnsColor.danger)
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
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchPolicies()
        }
    }
    
    @ViewBuilder
    // MARK: - Private Views
    private func policyRow(_ p: AccessPolicy) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
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
    
    // MARK: - Actions
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
