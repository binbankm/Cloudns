import SwiftUI

// MARK: - AddZoneView
// Apple HIG Compliant Add Domain Flow with Interactive Nameserver Guide

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
                                HStack(spacing: HIGTokens.Spacing.md) {
                                    ListRowIcon(icon: "server.rack", color: Color.higAccent)
                                    
                                    Text(ns)
                                        .font(HIGTypography.body.monospaced())
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        HIGFeedback.copied()
                                        UIPasteboard.general.string = ns
                                        ToastManager.shared.showCopied("Nameserver Copied")
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundStyle(Color.higAccent)
                                    }
                                    .buttonStyle(.plain)
                                    .higTouchTarget(44)
                                    .accessibilityLabel("Copy Nameserver \(ns)")
                                }
                            }

                            Button {
                                HIGFeedback.copied()
                                UIPasteboard.general.string = (zone.nameServers ?? []).joined(separator: "\n")
                                ToastManager.shared.showCopied("All Nameservers Copied")
                            } label: {
                                Label("Copy All Nameservers", systemImage: "doc.on.doc.fill")
                                    .font(HIGTypography.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .foregroundStyle(Color.higAccent)
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                        }

                        Section(header: Text("What to do next")) {
                            Label("Log in to your domain registrar (e.g. GoDaddy, Namecheap, Aliyun)", systemImage: "1.circle.fill")
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.primary)
                            Label("Find the DNS or Nameserver settings for \(zone.name)", systemImage: "2.circle.fill")
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.primary)
                            Label("Replace existing nameservers with the Cloudflare ones above", systemImage: "3.circle.fill")
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.primary)
                            Label("Save and wait for propagation (up to 24 hours)", systemImage: "4.circle.fill")
                                .font(HIGTypography.subheadline)
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
                            .font(HIGTypography.body.weight(.bold))
                            .foregroundStyle(Color.higAccent)
                            .higTouchTarget()
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
                            HStack(spacing: HIGTokens.Spacing.md) {
                                ListRowIcon(icon: "globe", color: Color.higAccent)
                                
                                TextField("example.com", text: $domainName)
                                    .font(HIGTypography.body)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                            }
                        }

                        if let error = viewModel.addZoneError {
                            Section {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(HIGColors.error)
                                    .font(HIGTypography.footnote)
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
                                            .padding(.trailing, HIGTokens.Spacing.xs)
                                    }
                                    Text(isSubmitting ? "Adding…" : "Add Domain")
                                        .font(HIGTypography.body.weight(.semibold))
                                    Spacer()
                                }
                                .foregroundStyle(domainName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting ? Color(.tertiaryLabel) : Color.higAccent)
                            }
                            .buttonStyle(.higPressable)
                            .higTouchTarget()
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
                            .font(HIGTypography.body)
                            .higTouchTarget()
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
