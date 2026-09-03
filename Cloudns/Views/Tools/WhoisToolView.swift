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
            Section(header: Text("Domain / Hostname"), footer: Text("Queries global RDAP (Registration Data Access Protocol) and authoritative WHOIS directories for registrar lifecycle dates.")) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(HIGTypography.body)
                        .foregroundStyle(Color.higAccent)
                        .accessibilityHidden(true)
                    
                    TextField("example.com", text: $viewModel.domainInput)
                        .keyboardType(.URL)
                        .font(HIGTypography.body.monospacedDigit())
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
                        .higTouchTarget(44)
                        .accessibilityLabel("Clear Input")
                    }
                }
                
                // Quick Presets
                ScrollView(.horizontal) {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                viewModel.domainInput = preset
                                performLookup()
                            } label: {
                                Text(preset)
                                    .font(HIGTypography.caption.weight(.medium).monospacedDigit())
                                    .padding(.horizontal, HIGTokens.Spacing.sm + 2)
                                    .padding(.vertical, HIGTokens.Spacing.xxs + 3)
                                    .background(Color.higAccent.opacity(0.12))
                                    .foregroundStyle(Color.higAccent)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.higPressable)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
                Button {
                    performLookup()
                } label: {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "globe")
                        }
                        Text(viewModel.isLoading ? "Querying RDAP…" : "Query WHOIS Directory")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading ? Color(.tertiaryLabel) : Color.higAccent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.higPressable)
                .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            
            if viewModel.isLoading && viewModel.info == nil {
                Section {
                    HIGContentState(.loading(message: "Querying Whois Database…"))
                        .padding(.vertical, HIGTokens.Spacing.sm)
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
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HIGColors.error)
                        Text(verbatim: error)
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(HIGColors.error)
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
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text("Domain Name")
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
                Text(info.domain)
                    .font(HIGTypography.headline)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            if let reg = info.registrar {
                HIGBadge(.active(reg), isCompact: true)
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = info.domain
                ToastManager.shared.showCopied("Domain Copied")
                HIGFeedback.copied()
            } label: {
                Label("Copy Domain Name", systemImage: "doc.on.doc")
            }
        }
        
        if let created = info.created {
            HStack {
                Text("Created Date")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(created.displayFormatted(date: .abbreviated, time: .shortened))
                    .font(HIGTypography.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
        if let updated = info.updated {
            HStack {
                Text("Updated Date")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(updated.displayFormatted(date: .abbreviated, time: .shortened))
                    .font(HIGTypography.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
        if let expires = info.expires {
            HStack {
                Text("Expiration Date")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: HIGTokens.Spacing.xxs) {
                    Text(expires.displayFormatted(date: .abbreviated, time: .shortened))
                        .font(HIGTypography.subheadline.monospacedDigit())
                        .foregroundStyle(.primary)
                    
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
                    if days > 0 {
                        Text("\(days) Days Remaining")
                            .font(HIGTypography.caption2.weight(.semibold))
                            .foregroundStyle(days > 30 ? HIGColors.success : HIGColors.error)
                    } else {
                        Text("Expired")
                            .font(HIGTypography.caption2.weight(.semibold))
                            .foregroundStyle(HIGColors.error)
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Statuses Rows
    @ViewBuilder
    private func statusesRows(info: WhoisInfo) -> some View {
        ForEach(info.statuses, id: \.self) { status in
            HStack(spacing: HIGTokens.Spacing.sm) {
                Circle()
                    .fill(Color.higAccent)
                    .frame(width: 6, height: 6)
                Text(verbatim: status)
                    .font(HIGTypography.caption.monospacedDigit())
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
                    .font(HIGTypography.caption)
                    .foregroundStyle(Color.higAccent)
                    .accessibilityHidden(true)
                Text(verbatim: ns.lowercased())
                    .font(HIGTypography.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    HIGFeedback.copied()
                    UIPasteboard.general.string = ns.lowercased()
                    ToastManager.shared.showCopied("Nameserver Copied")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(HIGTypography.caption)
                        .foregroundStyle(Color.higAccent)
                }
                .buttonStyle(.higPressable)
                .higTouchTarget(44)
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = ns.lowercased()
                    ToastManager.shared.showCopied("Nameserver Copied")
                    HIGFeedback.copied()
                } label: {
                    Label("Copy Nameserver", systemImage: "doc.on.doc")
                }
            }
        }
    }
}
