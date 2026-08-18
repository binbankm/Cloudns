import SwiftUI

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
                ToolbarItem(placement: .navigationBarTrailing) {
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
                AddPagesDomainSheet(viewModel: viewModel)
            }
            .alert("Delete Domain", isPresented: $showingDeleteAlert, presenting: domainToDelete) { dom in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteDomain(name: dom.name)
                            ToastManager.shared.showSuccess("Domain Deleted", message: dom.name)
                        } catch {
                            ToastManager.shared.showError("Failed to delete", message: error.localizedDescription)
                        }
                    }
                }
            } message: { dom in
                Text("Are you sure you want to remove domain '\(dom.name)' from this Pages project?")
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Connected Domains")) {
                    ForEach(PagesDomain.placeholders) { placeholder in
                        domainRow(placeholder)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !viewModel.domains.isEmpty {
                Section(header: Text("Connected Domains (\(viewModel.domains.count))")) {
                    ForEach(viewModel.domains) { domain in
                        domainRow(domain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    domainToDelete = domain
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if viewModel.hasFetchedData && viewModel.domains.isEmpty {
                StateOverlayView(
                    state: .empty(
                        icon: "globe",
                        title: "No Custom Domains",
                        message: "Connect your own apex domain or subdomain to serve this Pages project.",
                        actionTitle: "Add Domain",
                        action: { showingAddDomainSheet = true }
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private func domainRow(_ domain: PagesDomain) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(domain.name)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    CloudnsBadge((domain.status == "active") ? .active(domain.status?.capitalized ?? "Active") : .warning(domain.status?.capitalized ?? "Pending"), isCompact: true)

                    if let ssl = domain.sslStatus {
                        Text("• SSL: \(ssl.capitalized)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Pages Domain Sheet

private struct AddPagesDomainSheet: View {
    @ObservedObject var viewModel: PagesProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var domainName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Domain Name"), footer: Text("Enter a fully qualified domain name (e.g. docs.example.com or example.com).")) {
                    TextField("sub.example.com", text: $domainName)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Custom Domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                let trimmed = domainName.trimmingCharacters(in: .whitespacesAndNewlines)
                                try await viewModel.addDomain(name: trimmed)
                                HapticManager.impact(.medium)
                                ToastManager.shared.showSuccess("Domain Added", message: trimmed)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(domainName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
}
