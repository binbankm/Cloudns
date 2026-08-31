import SwiftUI

struct WhoisToolView: View {
    @StateObject private var viewModel = WhoisViewModel()
    @FocusState private var isFieldFocused: Bool
    
    let presets = ["cloudflare.com", "apple.com", "github.com", "google.com"]
    
    var body: some View {
        List {
            // 1. Query & Presets Section
            Section(header: Text("Domain / Hostname"), footer: Text("Queries global RDAP (Registration Data Access Protocol) and authoritative WHOIS directories for registrar lifecycle dates.")) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.body)
                        .foregroundStyle(.teal)
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
                        .accessibilityLabel("Clear input")
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
                                    .background(Color.teal.opacity(0.12))
                                    .foregroundStyle(.teal)
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
                        Text(viewModel.isLoading ? "Querying RDAP..." : "Query WHOIS Directory")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.info == nil {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Querying Whois Database...")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } else if let info = viewModel.info {
                // 2. Registration Hero Section
                Section(header: Text("Domain Registration")) {
                    registrationRows(info: info)
                }
                
                // 3. Domain Statuses Section
                if !info.statuses.isEmpty {
                    Section(header: Text("Registry Statuses (\(info.statuses.count))")) {
                        statusesRows(info: info)
                    }
                }
                
                // 4. Nameservers Section
                if !info.nameservers.isEmpty {
                    Section(header: Text("Authoritative Nameservers (\(info.nameservers.count))")) {
                        nameserversRows(info: info)
                    }
                }
            } else if let error = viewModel.errorMessage {
                Section(header: Text("Error")) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(verbatim: error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
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
        HIGFeedback.impact(.light)
        Task { await viewModel.performLookup() }
    }
    
    // MARK: - 2. Registration Rows
    @ViewBuilder
    private func registrationRows(info: WhoisInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Domain Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(info.domain)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            if let reg = info.registrar {
                HIGBadge(.active(reg), isCompact: true)
            }
        }
        
        if let created = info.created {
            HStack {
                Text("Created Date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(created, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
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
                Text(updated, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
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
                VStack(alignment: .trailing, spacing: 2) {
                    Text(expires, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
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
    
    @ViewBuilder
    private func infoRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(verbatim: value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - 3. Statuses Rows
    @ViewBuilder
    private func statusesRows(info: WhoisInfo) -> some View {
        ForEach(info.statuses, id: \.self) { status in
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.teal)
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
                    .foregroundStyle(.teal)
                    .accessibilityHidden(true)
                Text(verbatim: ns.lowercased())
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    UIPasteboard.general.string = ns.lowercased()
                    ToastManager.shared.showCopied()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .higTouchTarget()
            }
        }
    }
}
