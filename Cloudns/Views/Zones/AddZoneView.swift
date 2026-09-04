import SwiftUI

// MARK: - AddZoneView
// Apple HIG Compliant Add Domain Flow with Interactive Nameserver Guide (iOS 16.0+)

struct AddZoneView: View {
    @ObservedObject var viewModel: ZonesViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var domainName = ""
    @State private var createdZone: Zone?
    @State private var isSubmitting = false
    @State private var showingDiscardAlert = false
    
    init(viewModel: ZonesViewModel = ZonesViewModel(), isPresented: Binding<Bool> = .constant(true)) {
        self.viewModel = viewModel
        self._isPresented = isPresented
    }
    
    private var hasChanges: Bool {
        !domainName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var accentColor: Color {
        ThemeManager.shared.currentColor.color
    }
    
    var body: some View {
        Group {
            if let zone = createdZone {
                NavigationStack {
                    List {
                        Section(
                            header: Text("Assigned Nameservers"),
                            footer: Text("Update the nameservers at your domain registrar to the ones assigned above.")
                        ) {
                            ForEach(zone.nameServers ?? [], id: \.self) { ns in
                                HStack(spacing: 12) {
                                    ListRowIcon(icon: "server.rack", color: accentColor)
                                    
                                    Text(ns)
                                        .font(.body.monospaced())
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        copyToClipboard(ns, toast: "Nameserver Copied")
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundStyle(accentColor)
                                            .frame(minWidth: 44, minHeight: 44)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Copy Nameserver \(ns)")
                                }
                            }

                            Button {
                                let all = (zone.nameServers ?? []).joined(separator: "\n")
                                copyToClipboard(all, toast: "All Nameservers Copied")
                            } label: {
                                Label("Copy All Nameservers", systemImage: "doc.on.doc.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .foregroundStyle(accentColor)
                            .padding(.vertical, 2)
                        }

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
                                dismiss()
                            }
                            .font(.body.weight(.bold))
                            .foregroundStyle(accentColor)
                        }
                    }
                }
            } else {
                NavigationStack {
                    Form {
                        Section(
                            header: Text("Domain Information"),
                            footer: Text("Enter the root domain you want to add to Cloudflare, e.g. example.com")
                        ) {
                            HStack(spacing: 12) {
                                ListRowIcon(icon: "globe", color: accentColor)
                                
                                TextField("example.com", text: $domainName)
                                    .font(.body)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                            }
                        }

                        if let error = viewModel.addZoneError {
                            Section {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                            }
                        }

                        Section {
                            Button {
                                Task {
                                    isSubmitting = true
                                    if let newZone = await viewModel.addZone(name: domainName.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                        ToastManager.shared.showSuccess("Domain Added", icon: "checkmark.circle.fill")
                                        HIGFeedback.success()
                                        createdZone = newZone
                                    } else {
                                        ToastManager.shared.showError(LocalizedStringKey(viewModel.addZoneError ?? "Failed to Add Domain"))
                                        HIGFeedback.error()
                                    }
                                    isSubmitting = false
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isSubmitting {
                                        ProgressView()
                                            .padding(.trailing, 6)
                                    }
                                    Text(isSubmitting ? "Adding…" : "Add Domain")
                                        .font(.body.weight(.semibold))
                                    Spacer()
                                }
                                .foregroundStyle(domainName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting ? Color(.tertiaryLabel) : accentColor)
                            }
                            .disabled(domainName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .navigationTitle("Add Domain")
                    .navigationBarTitleDisplayMode(.inline)
                    .presentationDragIndicator(.visible)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                if hasChanges {
                                    showingDiscardAlert = true
                                } else {
                                    isPresented = false
                                    dismiss()
                                }
                            }
                            .font(.body)
                        }
                    }
                    .interactiveDismissDisabled(hasChanges && !isSubmitting)
                    .confirmationDialog("Discard Domain?", isPresented: $showingDiscardAlert, titleVisibility: .visible) {
                        Button("Discard", role: .destructive) {
                            isPresented = false
                            dismiss()
                        }
                        Button("Keep Editing", role: .cancel) {}
                    }
                }
            }
        }
        .higToast()
    }
}
