import SwiftUI

struct WhoisToolView: View {
    @StateObject private var viewModel = WhoisViewModel()
    @FocusState private var isFieldFocused: Bool
    
    let presets = ["cloudflare.com", "apple.com", "github.com", "google.com"]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
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
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
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
                                .background(Color.teal.opacity(0.10))
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
                            .tint(.white)
                    } else {
                        Image(systemName: "globe")
                    }
                    Text(viewModel.isLoading ? "Querying RDAP..." : "Query WHOIS Directory")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .controlSize(.regular)
            .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    private func performLookup() {
        isFieldFocused = false
        HapticManager.impact(.light)
        Task { await viewModel.performLookup() }
    }
    
    // MARK: - 2. Registration Card
    @ViewBuilder
    private func registrationCard(info: WhoisInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
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
            
            VStack(spacing: 10) {
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
                        VStack(alignment: .trailing, spacing: 2) {
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
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Registry Statuses (\(info.statuses.count))")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(info.statuses, id: \.self) { status in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 6, height: 6)
                        Text(status)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - 4. Nameservers Card
    @ViewBuilder
    private func nameserversCard(info: WhoisInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Authoritative Nameservers (\(info.nameservers.count))")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Divider()
            
            VStack(spacing: 8) {
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
                            ToastManager.shared.showCopied("\(ns.lowercased()) copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - Error Card
    @ViewBuilder
    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Lookup Failed")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cloudnsCard(style: .frosted, cornerRadius: 16)
    }
    
    // MARK: - Skeleton View
    private var loadingSkeletonView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Domain Registration")
                    .font(.caption)
                Text("example.com")
                    .font(.title3.weight(.bold))
                Divider()
                Text("Created Date")
                Text("Expiration Date")
            }
            .padding(16)
            .cloudnsCard(style: .frosted, cornerRadius: 16)
            .skeletonLoading(true)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        DateFormatters.yearMonthDayHourMinute.string(from: date)
    }
}
