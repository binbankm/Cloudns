import SwiftUI

struct RedirectRulesView: View {
    let zoneId: String
    @State private var rules: [RedirectRuleItem] = []
    @State private var isLoading = false
    @State private var hasFetchedData = false
    @State private var errorMessage: String?
    @State private var showingAddSheet = false
    @State private var ruleToDelete: RedirectRuleItem? = nil
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            contentView
        }
        .navigationTitle("Redirect Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("添加重定向规则")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRedirectRuleSheetView(zoneId: zoneId) {
                Task { await fetchRules() }
            }
        }
        .alert("Delete Redirect Rule", isPresented: $showingDeleteAlert, presenting: ruleToDelete) { rule in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await CloudflareAPIClient.shared.deleteRedirectRule(zoneId: zoneId, ruleId: rule.id)
                        ToastManager.shared.showSuccess("Rule Deleted", message: rule.description ?? "Redirect Rule")
                        await fetchRules()
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                }
            }
        } message: { rule in
            Text("Are you sure you want to delete redirect rule '\(rule.description ?? "Rule")'?")
        }
        .refreshable {
            await fetchRules()
        }
        .task {
            if !hasFetchedData {
                await fetchRules()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading && !hasFetchedData {
            List {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonRowView()
                }
            }
            .listStyle(.insetGrouped)
        } else if let err = errorMessage, !hasFetchedData {
            EmptyStateView.error(
                message: LocalizedStringKey(err),
                retryAction: { Task { await fetchRules() } }
            )
        } else if rules.isEmpty {
            EmptyStateView(
                icon: "arrow.turn.up.right",
                title: "No Redirect Rules",
                message: "Configure URL redirection rules to permanently (301) or temporarily (302) redirect incoming visitors.",
                actionTitle: "Create Redirect Rule",
                action: { showingAddSheet = true }
            )
        } else {
            List {
                Section(header: Text("Configured Redirects (\(rules.count))")) {
                    ForEach(rules) { rule in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(rule.description ?? "Redirect Rule")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if let status = rule.statusCode {
                                    Text("\(status)")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .cornerRadius(4)
                                }
                            }
                            
                            if let expr = rule.expression {
                                Text(expr)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            if let target = rule.targetUrl {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                    Text(target)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.blue)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 3)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                ruleToDelete = rule
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    private func fetchRules() async {
        isLoading = true
        errorMessage = nil
        do {
            self.rules = try await CloudflareAPIClient.shared.getRedirectRules(zoneId: zoneId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct AddRedirectRuleSheetView: View {
    let zoneId: String
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleDescription = ""
    @State private var expression = "http.request.uri.path eq \"/old-path\""
    @State private var targetUrl = "https://example.com/new-path"
    @State private var statusCode = 301
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Description")) {
                    TextField("Rule Name", text: $ruleDescription)
                }
                
                Section(header: Text("Matching Expression"), footer: Text("Cloudflare wirefilter expression defining which incoming requests trigger redirection.")) {
                    TextField("Expression", text: $expression)
                        .font(.footnote)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Redirect Target & Code")) {
                    TextField("Target URL (e.g. https://example.com/new)", text: $targetUrl)
                        .font(.footnote)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    Picker("Status Code", selection: $statusCode) {
                        Text("301 - Moved Permanently").tag(301)
                        Text("302 - Found (Temporary)").tag(302)
                        Text("307 - Temporary Redirect").tag(307)
                        Text("308 - Permanent Redirect").tag(308)
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Redirect Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await CloudflareAPIClient.shared.createRedirectRule(
                                    zoneId: zoneId,
                                    description: ruleDescription.trimmingCharacters(in: .whitespaces),
                                    expression: expression.trimmingCharacters(in: .whitespaces),
                                    targetUrl: targetUrl.trimmingCharacters(in: .whitespaces),
                                    statusCode: statusCode
                                )
                                ToastManager.shared.showSuccess("Redirect Rule", message: "Rule created successfully")
                                onCreated()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(ruleDescription.trimmingCharacters(in: .whitespaces).isEmpty || targetUrl.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .toastContainer()
        }
    }
}
