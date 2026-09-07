import SwiftUI

// MARK: - AccessAppDetailView
// Apple HIG Compliant Cloudflare Access Application Inspection & Assigned Policies

struct AccessAppDetailView: View {
    let accountId: String
    let app: AccessApp
    @State private var policies: [AccessPolicy] = []
    @State private var isLoadingPolicies = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            Section("Application Details") {
                LabeledContent("Name", value: app.name)
                    .font(.body)
                
                LabeledContent("Domain", value: app.domain)
                    .font(.body.monospaced())
                
                if let type = app.type {
                    LabeledContent("Type") {
                        Text(type.capitalized)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.purple.opacity(0.12)))
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
            
            Section("Access Policies (\(policies.count))") {
                if let err = errorMessage, policies.isEmpty {
                    Text(verbatim: err)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if policies.isEmpty && !isLoadingPolicies {
                    Text("No policies assigned to this application.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(policies) { p in
                        policyRow(p)
                            .contextMenu {
                                Button {
                                    copyToClipboard(p.name, toast: "Policy Name Copied")
                                } label: {
                                    Label("Copy Policy Name", systemImage: "doc.on.doc")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: isLoadingPolicies && policies.isEmpty,
            loadingMessage: "Loading Policies…"
        )
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchPolicies()
        }
    }
    
    @ViewBuilder
    private func policyRow(_ p: AccessPolicy) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(p.name)
                    .font(.body.weight(.medium))
                Text("Decision: \(p.decision.capitalized)")
                    .font(.caption2)
                    .foregroundStyle(p.decision.lowercased() == "allow" ? .green : .orange)
            }
            Spacer()
            if let prec = p.precedence {
                Text("#\(prec)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
