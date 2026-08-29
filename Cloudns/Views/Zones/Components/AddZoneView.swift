import SwiftUI

// MARK: - AddZoneView

struct AddZoneView: View {
    @ObservedObject var viewModel: ZonesViewModel
    @Binding var isPresented: Bool
    @State private var domainName = ""
    @State private var createdZone: Zone?
    @State private var isSubmitting = false
    
    init(viewModel: ZonesViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
    }
    
    var body: some View {
        if let zone = createdZone {
            NavigationStack {
                // ── Step 2: Nameserver Instructions ───────────────────
                List {
                    Section(
                        header: Text("Assigned Nameservers"),
                        footer: Text("Update the nameservers at your domain registrar to the ones assigned above.")
                    ) {
                        ForEach(zone.nameServers ?? [], id: \.self) { ns in
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                Text(ns)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = ns
                                    ToastManager.shared.showCopied("Nameserver copied")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Copy nameserver \(ns)")
                            }
                        }

                        Button {
                            UIPasteboard.general.string = (zone.nameServers ?? []).joined(separator: "\n")
                            ToastManager.shared.showCopied("All nameservers copied")
                        } label: {
                            Label("Copy All Nameservers", systemImage: "doc.on.doc.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .foregroundStyle(.blue)
                    }

                    // Instructions
                    Section(header: Text("What to do next")) {
                        Label("Log in to your domain registrar (e.g. GoDaddy, Namecheap, Aliyun)", systemImage: "1.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Label("Find the DNS or Nameserver settings for \(zone.name)", systemImage: "2.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Label("Replace existing nameservers with the Cloudflare ones above", systemImage: "3.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Label("Save and wait for propagation (up to 24 hours)", systemImage: "4.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Section(
                        footer: Text("Your domain will show as Pending until Cloudflare detects the nameserver update. This can take a few minutes to 24 hours.")
                    ) {
                        EmptyView()
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Setup Nameservers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
                        .fontWeight(.bold)
                    }
                }
                .toastContainer()
            }
        } else {
            NavigationStack {
                // ── Step 1: Enter Domain Name ─────────────────────────
                Form {
                    Section(
                        header: Text("Domain Information"),
                        footer: Text("Enter the root domain you want to add to Cloudflare, e.g. example.com")
                    ) {
                        TextField("example.com", text: $domainName)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit {
                                guard !domainName.isEmpty && !isSubmitting else { return }
                                submitDomain()
                            }
                    }

                    if let error = viewModel.addZoneError {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .accessibilityHidden(true)
                                Text(error)
                                    .foregroundStyle(.primary)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle("Add Domain")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            submitDomain()
                        }
                        .disabled(domainName.isEmpty || isSubmitting)
                        .fontWeight(.bold)
                    }
                }
                .overlay {
                    if isSubmitting {
                        ZStack {
                            Color.black.opacity(0.15).ignoresSafeArea()
                            VStack(spacing: 12) {
                                ProgressView()
                                    .controlSize(.large)
                                Text("Adding domain...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .toastContainer()
            }
        }
    }
    
    private func submitDomain() {
        Task {
            isSubmitting = true
            let zone = await viewModel.addZone(
                name: domainName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isSubmitting = false
            if let zone = zone {
                createdZone = zone
            }
        }
    }
}
