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
                .accessibilityLabel("添加域名")
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
            .toastContainer()
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if viewModel.isLoading && viewModel.domains.isEmpty {
                List {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if viewModel.domains.isEmpty {
                EmptyStateView(
                    icon: "globe",
                    title: "No Custom Domains",
                    message: "Connect your own apex domain or subdomain to serve this Pages project.",
                    actionTitle: "Add Domain",
                    action: {
                        showingAddDomainSheet = true
                    }
                )
            } else {
                List {
                    Section(header: Text("Connected Domains (\(viewModel.domains.count))")) {
                        ForEach(viewModel.domains) { domain in
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(domain.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill((domain.status == "active") ? Color.green : Color.orange)
                                                .frame(width: 6, height: 6)
                                            Text(domain.status?.capitalized ?? "Active")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    domainToDelete = domain
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
            .toastContainer()
        }
    }
}
