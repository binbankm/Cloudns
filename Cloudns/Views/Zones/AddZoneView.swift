import SwiftUI

// MARK: - AddZoneView

struct AddZoneView: View {
    @ObservedObject var viewModel: ZonesViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var domainName = ""
    @State private var createdZone: Zone?
    @State private var isSubmitting = false
    
    init(viewModel: ZonesViewModel = ZonesViewModel(), isPresented: Binding<Bool> = .constant(true)) {
        self.viewModel = viewModel
        self._isPresented = isPresented
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
                                    HIGFeedback.copied()
                                    UIPasteboard.general.string = ns
                                    ToastManager.shared.showCopied("Nameserver Copied")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                                .higTouchTarget()
                                .accessibilityLabel("Copy Nameserver \(ns)")
                            }
                        }

                        Button {
                            HIGFeedback.copied()
                            UIPasteboard.general.string = (zone.nameServers ?? []).joined(separator: "\n")
                            ToastManager.shared.showCopied("All Nameservers Copied")
                        } label: {
                            Label("Copy All Nameservers", systemImage: "doc.on.doc.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .foregroundStyle(.blue)
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
                        }
                        .fontWeight(.bold)
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
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            TextField("example.com", text: $domainName)
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
                                    HIGFeedback.success()
                                    createdZone = newZone
                                } else {
                                    HIGFeedback.error()
                                }
                                isSubmitting = false
                            }
                        } label: {
                            HStack {
                                Spacer()
                                if isSubmitting {
                                    ProgressView()
                                        .padding(.trailing, 4)
                                }
                                Text(isSubmitting ? "Adding…" : "Add Domain")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundStyle(domainName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting ? Color(.tertiaryLabel) : Color.accentColor)
                        }
                        .buttonStyle(.higPressable)
                        .disabled(domainName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle("Add Domain")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                            dismiss()
                        }
                    }
                }
                }
            }
        }
        .higToast()
    }
}
