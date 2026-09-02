import SwiftUI

// MARK: - PagesDomainsView
// Apple HIG Compliant Cloudflare Pages Custom Domains Management

struct PagesDomainsView: View {
    let accountId: String
    let projectName: String
    @ObservedObject var viewModel: PagesProjectDetailViewModel
    
    @State private var showingAddDomainSheet = false
    @State private var domainToDelete: PagesDomain?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        contentView
            .navigationTitle("Custom Domains")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddDomainSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Custom Domain")
                    .higTouchTarget(44)
                }
            }
            .refreshable {
                await viewModel.fetchProjectDetails()
            }
            .sheet(isPresented: $showingAddDomainSheet) {
                AddPagesDomainSheetView(viewModel: viewModel)
                    .higToast()
            }
            .confirmationDialog("Delete Domain", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: domainToDelete) { dom in
                Button("Delete '\(dom.name)'", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteDomain(name: dom.name)
                            ToastManager.shared.showSuccess("Custom Domain Removed", icon: "trash.fill")
                            HIGFeedback.success()
                        } catch {
                            ToastManager.shared.showError("Failed to Remove Domain")
                            HIGFeedback.error()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { dom in
                Text("Are you sure you want to remove domain '\(dom.name)' from this Pages project?")
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.domains.isEmpty {
                Section(header: Text("Connected Domains (\(viewModel.domains.count))")) {
                    ForEach(viewModel.domains) { domain in
                        domainRow(domain)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = domain.name
                                    ToastManager.shared.showCopied("Domain Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Domain", systemImage: "doc.on.doc")
                                }
                                
                                if let url = URL(string: "https://\(domain.name)") {
                                    Link(destination: url) {
                                        Label("Open Domain in Safari", systemImage: "safari")
                                    }
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    domainToDelete = domain
                                    showingDeleteAlert = true
                                    HIGFeedback.impact(.medium)
                                } label: {
                                    Label("Delete Domain", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
                                    domainToDelete = domain
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(HIGColors.error)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Custom Domains…"))
            } else if viewModel.hasFetchedData && viewModel.domains.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Custom Domains",
                        systemImage: "globe",
                        description: "Connect your own apex domain or subdomain to serve this Pages project.",
                        actionTitle: "Add Domain",
                        action: { showingAddDomainSheet = true }
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private func domainRow(_ domain: PagesDomain) -> some View {
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "globe", color: .blue)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(domain.name)
                    .font(HIGTypography.body)
                    .foregroundStyle(.primary)
                
                if let status = domain.status {
                    Text(status.capitalized)
                        .font(HIGTypography.caption2)
                        .foregroundStyle(status.lowercased() == "active" ? HIGColors.success : .orange)
                }
            }
            
            Spacer()
            
            if let status = domain.status {
                HIGBadge(status.lowercased() == "active" ? .active : .warning(status.capitalized), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}

// MARK: - AddPagesDomainSheetView (Inlined & Cohesive)

struct AddPagesDomainSheetView: View {
    @ObservedObject var viewModel: PagesProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var domain = ""
    @State private var isAdding = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Domain Name"),
                    footer: Text("Enter the custom domain or subdomain you want to route to this project (e.g. blog.example.com).")
                ) {
                    TextField("blog.example.com", text: $domain)
                        .font(HIGTypography.body)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: HIGTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HIGColors.error)
                            Text(verbatim: err)
                                .font(HIGTypography.caption)
                                .foregroundStyle(HIGColors.error)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Custom Domain")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            isAdding = true
                            errorMessage = nil
                            do {
                                try await viewModel.addDomain(name: domain.trimmingCharacters(in: .whitespaces))
                                ToastManager.shared.showSuccess("Domain Connected", icon: "globe")
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isAdding = false
                        }
                    }
                    .disabled(domain.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isAdding)
        }
    }
}
