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
            Section(header: Text("Application Details")) {
                LabeledContent("Name", value: app.name)
                    .font(HIGTypography.body)
                
                LabeledContent("Domain", value: app.domain)
                    .font(HIGTypography.body.monospaced())
                
                if let type = app.type {
                    LabeledContent("Type") {
                        HIGBadge(.custom(color: .purple, text: type.capitalized), isCompact: true)
                    }
                }
                
                if let aud = app.aud {
                    LabeledContent("Audience Tag (AUD)") {
                        Text(aud)
                            .font(HIGTypography.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("Access Policies (\(policies.count))")) {
                if isLoadingPolicies && policies.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading Policies…")
                        Spacer()
                    }
                    .padding(.vertical, HIGTokens.Spacing.xs)
                } else if let err = errorMessage, policies.isEmpty {
                    Text(verbatim: err)
                        .font(HIGTypography.caption)
                        .foregroundStyle(HIGColors.error)
                } else if policies.isEmpty {
                    Text("No policies assigned to this application.")
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(policies) { p in
                        policyRow(p)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = p.name
                                    ToastManager.shared.showCopied("Policy Name Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Policy Name", systemImage: "doc.on.doc")
                                }
                            }
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
        HStack(spacing: HIGTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(p.name)
                    .font(HIGTypography.body.weight(.medium))
                Text("Decision: \(p.decision.capitalized)")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(p.decision.lowercased() == "allow" ? HIGColors.success : .orange)
            }
            Spacer()
            if let prec = p.precedence {
                Text("#\(prec)")
                    .font(HIGTypography.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
