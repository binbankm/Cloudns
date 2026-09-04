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
                }
            }
            .refreshable {
                await viewModel.fetchProjectDetails()
            }
            .sheet(isPresented: $showingAddDomainSheet) {
                AddPagesDomainSheetView(viewModel: viewModel)
            }
            .confirmationDialog("Delete Domain", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: domainToDelete) { dom in
                Button("Delete '\(dom.name)'", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteDomain(name: dom.name)
                            ToastManager.shared.showSuccess("Custom Domain Removed", icon: "trash.fill")
                            HapticManager.notification(.success)
                        } catch {
                            ToastManager.shared.showError("Failed to Remove Domain")
                            HapticManager.notification(.error)
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
                                    copyToClipboard(domain.name, toast: "Domain Copied")
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
                                    HapticManager.impact(.medium)
                                } label: {
                                    Label("Delete Domain", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    domainToDelete = domain
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Custom Domains…",
            isEmpty: viewModel.hasFetchedData && viewModel.domains.isEmpty,
            emptyTitle: "No Custom Domains",
            emptySystemImage: "globe",
            emptyDescription: "Connect your own apex domain or subdomain to serve this Pages project.",
            emptyActionTitle: "Add Domain",
            emptyAction: { showingAddDomainSheet = true }
        )
    }
    
    @ViewBuilder
    private func domainRow(_ domain: PagesDomain) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "globe", color: .blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(domain.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                if let status = domain.status {
                    Text(status.capitalized)
                        .font(.caption2)
                        .foregroundStyle(status.lowercased() == "active" ? .green : .orange)
                }
            }
            
            Spacer()
            
            if let status = domain.status {
                let isActive = status.lowercased() == "active"
                Text(status.capitalized)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isActive ? .green : .orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((isActive ? Color.green : Color.orange).opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
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
                        .font(.body)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            isAdding = true
                            errorMessage = nil
                            do {
                                try await viewModel.addDomain(name: domain.trimmingCharacters(in: .whitespaces))
                                ToastManager.shared.showSuccess("Domain Connected", icon: "globe")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isAdding = false
                        }
                    }
                    .disabled(domain.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
                }
            }
            .interactiveDismissDisabled(isAdding)
        }
    }
}
