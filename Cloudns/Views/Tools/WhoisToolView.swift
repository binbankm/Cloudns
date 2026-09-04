import SwiftUI

// MARK: - WhoisToolView
// Apple HIG Compliant RDAP & WHOIS Domain Lifecycle Directory

struct WhoisToolView: View {
    @StateObject private var viewModel = WhoisViewModel()
    @FocusState private var isFieldFocused: Bool
    
    let presets = ["cloudflare.com", "apple.com", "github.com", "google.com"]
    
    var body: some View {
        List {
            // 1. Query & Presets Section
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    TextField("example.com", text: $viewModel.domainInput)
                        .keyboardType(.URL)
                        .font(.body.monospacedDigit())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            performLookup()
                        }
                    
                    if !viewModel.domainInput.isEmpty {
                        Button {
                            viewModel.domainInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear Input")
                    }
                }
                
                // Quick Presets
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                viewModel.domainInput = preset
                                performLookup()
                            } label: {
                                Text(preset)
                                    .font(.caption.weight(.medium).monospacedDigit())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
                Button {
                    performLookup()
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "globe")
                        }
                        Text(viewModel.isLoading ? "Querying RDAP…" : "Query WHOIS Directory")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            } header: {
                Text("Domain / Hostname")
            } footer: {
                Text("Queries global RDAP (Registration Data Access Protocol) and authoritative WHOIS directories for registrar lifecycle dates.")
            }
            
            if let info = viewModel.info {
                // 2. Registration Hero Section
                Section("Domain Registration") {
                    registrationRows(info: info)
                }
                
                // 3. Domain Statuses Section
                if !info.statuses.isEmpty {
                    Section("Registry Statuses (\(info.statuses.count))") {
                        statusesRows(info: info)
                    }
                }
                
                // 4. Nameservers Section
                if !info.nameservers.isEmpty {
                    Section("Authoritative Nameservers (\(info.nameservers.count))") {
                        nameserversRows(info: info)
                    }
                }
            } else if let error = viewModel.errorMessage {
                Section("Error") {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(verbatim: error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .listState(
            isLoading: viewModel.isLoading && viewModel.info == nil,
            loadingMessage: "Querying Whois Database…"
        )
        .refreshable {
            if !viewModel.domainInput.isEmpty {
                await viewModel.performLookup()
            }
        }
        .navigationTitle("WHOIS & RDAP")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performLookup() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.performLookup() }
    }
    
    // MARK: - 2. Registration Rows
    @ViewBuilder
    private func registrationRows(info: WhoisInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Domain Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(info.domain)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            if let reg = info.registrar {
                Text(reg)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.12)))
            }
        }
        .contextMenu {
            Button {
                copyToClipboard(info.domain, toast: "Domain Copied")
            } label: {
                Label("Copy Domain Name", systemImage: "doc.on.doc")
            }
        }
        
        if let created = info.created {
            HStack {
                Text("Created Date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(created.displayFormatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
        if let updated = info.updated {
            HStack {
                Text("Updated Date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(updated.displayFormatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
        if let expires = info.expires {
            HStack {
                Text("Expiration Date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expires.displayFormatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.primary)
                    
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
                    if days > 0 {
                        Text("\(days) Days Remaining")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(days > 30 ? .green : .red)
                    } else {
                        Text("Expired")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Statuses Rows
    @ViewBuilder
    private func statusesRows(info: WhoisInfo) -> some View {
        ForEach(info.statuses, id: \.self) { status in
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                Text(verbatim: status)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: - 4. Nameservers Rows
    @ViewBuilder
    private func nameserversRows(info: WhoisInfo) -> some View {
        ForEach(info.nameservers, id: \.self) { ns in
            HStack {
                Image(systemName: "server.rack")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text(verbatim: ns.lowercased())
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    copyToClipboard(ns.lowercased(), toast: "Nameserver Copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .contextMenu {
                Button {
                    copyToClipboard(ns.lowercased(), toast: "Nameserver Copied")
                } label: {
                    Label("Copy Nameserver", systemImage: "doc.on.doc")
                }
            }
        }
    }
}
