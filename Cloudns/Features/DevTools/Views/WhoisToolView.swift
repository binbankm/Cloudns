import SwiftUI

struct WhoisToolView: View {
    // MARK: - Properties
    @StateObject private var viewModel = WhoisViewModel()
    @ObservedObject private var historyManager = DevToolsHistoryManager.shared
    @FocusState private var isFieldFocused: Bool
    
    let presets = ["cloudflare.com", "apple.com", "github.com", "google.com"]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            CloudnsColor.groupedBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: CloudnsSpacing.md) {
                    // 1. Query & Presets Card
                    queryCard
                    
                    if viewModel.isLoading && viewModel.info == nil {
                        loadingSkeletonView
                    } else if let info = viewModel.info {
                        // 2. Registration Hero Card
                        registrationCard(info: info)
                        
                        // 3. Domain Statuses Card
                        if !info.statuses.isEmpty {
                            statusesCard(info: info)
                        }
                        
                        // 4. Nameservers Card
                        if !info.nameservers.isEmpty {
                            nameserversCard(info: info)
                        }
                    } else if let error = viewModel.errorMessage {
                        errorCard(message: error)
                    }
                }
                .padding(.horizontal, CloudnsSpacing.md)
                .padding(.vertical, CloudnsSpacing.mdSmall)
                .centerConstrainedWidth(maxWidth: 840)
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                if !viewModel.domainInput.isEmpty {
                    HapticManager.impact(.light)
                    await viewModel.performLookup()
                }
            }
        }
        .navigationTitle("WHOIS & RDAP")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 1. Query Card
    private var queryCard: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            HStack(spacing: CloudnsSpacing.smMd) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
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
                    .accessibilityLabel("Clear input")
                }
            }
            .padding(CloudnsSpacing.mdSmall)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            
            QueryHistoryChipsView(
                history: historyManager.whoisHistory,
                onSelect: { domain in
                    viewModel.domainInput = domain
                    performLookup()
                },
                onClear: {
                    historyManager.clearHistory(for: .whois)
                }
            )
            
            // Quick Presets
            ScrollView(.horizontal) {
                HStack(spacing: CloudnsSpacing.sm) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            viewModel.domainInput = preset
                            performLookup()
                        } label: {
                            Text(preset)
                                .font(.caption.weight(.medium).monospacedDigit())
                                .padding(.horizontal, CloudnsSpacing.smMd)
                                .padding(.vertical, CloudnsSpacing.xs)
                                .background(CloudnsColor.security.opacity(0.10))
                                .foregroundStyle(.teal)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
            
            CloudnsButton(
                viewModel.isLoading ? "Querying RDAP..." : "Query WHOIS Directory",
                icon: "globe",
                style: .primary(color: .teal),
                size: .regular,
                isFullWidth: true,
                isLoading: viewModel.isLoading,
                disabled: viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                performLookup()
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Actions
    private func performLookup() {
        isFieldFocused = false
        guard !viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        historyManager.recordQuery(viewModel.domainInput, for: .whois)
        HapticManager.impact(.light)
        Task {
            await viewModel.performLookup()
        }
    }
    
    // MARK: - 2. Registration Card
    @ViewBuilder
    private func registrationCard(info: WhoisInfo) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            HStack {
                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    Text("Domain Registration")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(info.domain)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                if let reg = info.registrar {
                    CloudnsBadge(.active(reg), isCompact: true)
                }
            }
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.smMd) {
                if let created = info.created {
                    infoRow(title: "Created Date", value: formatDate(created))
                }
                if let updated = info.updated {
                    infoRow(title: "Updated Date", value: formatDate(updated))
                }
                if let expires = info.expires {
                    HStack {
                        Text("Expiration Date")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: CloudnsSpacing.xxs) {
                            Text(formatDate(expires))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.primary)
                            
                            let days = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
                            Text(days > 0 ? "\(days) days remaining" : "Expired")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(days > 30 ? .green : .red)
                        }
                    }
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    @ViewBuilder
    private func infoRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - 3. Statuses Card
    @ViewBuilder
    private func statusesCard(info: WhoisInfo) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Registry Statuses (\(info.statuses.count))")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                ForEach(info.statuses, id: \.self) { status in
                    HStack(spacing: CloudnsSpacing.sm) {
                        Circle()
                            .fill(CloudnsColor.security)
                            .frame(width: 6, height: 6)
                        Text(status)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - 4. Nameservers Card
    @ViewBuilder
    private func nameserversCard(info: WhoisInfo) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            Text("Authoritative Nameservers (\(info.nameservers.count))")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: CloudnsSpacing.sm) {
                ForEach(info.nameservers, id: \.self) { ns in
                    HStack {
                        Image(systemName: "server.rack")
                            .font(.caption)
                            .foregroundStyle(.teal)
                            .accessibilityHidden(true)
                        Text(ns.lowercased())
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.primary)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = ns.lowercased()
                            HapticManager.notification(.success)
                            CloudnsToastManager.shared.showCopied("\(ns.lowercased()) copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(CloudnsColor.brand)
                        }
                    }
                    .padding(.vertical, CloudnsSpacing.xxs)
                }
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(CloudnsColor.brandAccent)
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Lookup Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(CloudnsSpacing.md)
        .cloudnsCard(style: .frosted)
    }
    
    // MARK: - Skeleton View
    private var loadingSkeletonView: some View {
        VStack(spacing: CloudnsSpacing.md) {
            VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
                Text("Domain Registration")
                    .font(.caption)
                Text("example.com")
                    .font(.title3.weight(.bold))
                Divider()
                Text("Created Date")
                Text("Expiration Date")
            }
            .padding(CloudnsSpacing.md)
            .cloudnsCard(style: .frosted)
            .skeletonLoading(true)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        DateFormatters.yearMonthDayHourMinute.string(from: date)
    }
}
