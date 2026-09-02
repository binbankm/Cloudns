import SwiftUI

// MARK: - SecurityEventsView
// Apple HIG Compliant Cloudflare Security Events Log & Threat Activity Timeline

struct SecurityEventsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SecurityEventsViewModel()
    @State private var searchText = ""
    
    private var displayedEvents: [SecurityEvent] {
        if searchText.isEmpty { return viewModel.events }
        return viewModel.events.filter {
            $0.clientIP.localizedStandardContains(searchText) ||
            $0.clientCountryName.localizedStandardContains(searchText) ||
            $0.action.localizedStandardContains(searchText) ||
            $0.host.localizedStandardContains(searchText) ||
            ($0.clientAsn ?? "").localizedStandardContains(searchText)
        }
    }
    
    var body: some View {
        List {
            if !displayedEvents.isEmpty {
                Section(header: Text("Security Events (\(displayedEvents.count))")) {
                    ForEach(displayedEvents) { event in
                        SecurityEventCardView(event: event)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = event.clientIP
                                    ToastManager.shared.showCopied("Client IP Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy IP Address", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = event.host
                                    ToastManager.shared.showCopied("Host Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Host URL", systemImage: "link")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search IP, Country or Action"
        )
        .navigationTitle("Security Events")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Security Events…"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.events.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchEvents(zoneId: zoneId) }
                        }
                    )
                )
            } else if viewModel.hasFetchedData && viewModel.events.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No Security Events",
                        systemImage: "checkmark.shield",
                        description: "Your site hasn't blocked any threats recently. Everything is secure!"
                    )
                )
            } else if viewModel.hasFetchedData && displayedEvents.isEmpty && !searchText.isEmpty {
                HIGContentState(.search(query: searchText))
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchEvents(zoneId: zoneId)
            }
        }
        .refreshable {
            await viewModel.fetchEvents(zoneId: zoneId)
        }
    }
}

// MARK: - SecurityEventCardView (Inlined & Cohesive)

struct SecurityEventCardView: View {
    let event: SecurityEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
            HStack {
                HIGBadge(.custom(color: colorForAction(event.action), text: actionDisplayName(event.action)), isCompact: true)
                
                Spacer()
                
                if let date = DateFormatters.parseISO8601(event.datetime) {
                    Text(date.displayFormatted(date: .abbreviated, time: .shortened))
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(event.datetime)
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                    Text("IP Address")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Text(countryFlag(countryCode: event.clientCountryName))
                        Text(event.clientIP)
                            .font(HIGTypography.subheadline.monospacedDigit())
                    }
                }
                
                Spacer()
                
                if let asn = event.clientAsn {
                    VStack(alignment: .trailing, spacing: HIGTokens.Spacing.xxs) {
                        Text("ASN")
                            .font(HIGTypography.caption2)
                            .foregroundStyle(.secondary)
                        Text("AS\(asn)")
                            .font(HIGTypography.subheadline)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text("Source / Engine")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
                Text(event.source.capitalized)
                    .font(HIGTypography.footnote)
            }
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text("Target URL")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
                Text(event.host)
                    .font(HIGTypography.footnote.monospacedDigit())
                    .foregroundStyle(Color.higAccent)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    private func actionDisplayName(_ action: String) -> String {
        switch action {
        case "block": return "BLOCK"
        case "challenge": return "LEGACY CAPTCHA"
        case "js_challenge": return "JS CHALLENGE"
        case "managed_challenge": return "MANAGED CHALLENGE"
        case "log": return "LOG"
        case "connectionClose": return "CONNECTION CLOSE"
        default: return action.uppercased()
        }
    }
    
    private func colorForAction(_ action: String) -> Color {
        switch action {
        case "block", "connectionClose": return HIGColors.error
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "log": return .blue
        default: return .secondary
        }
    }
    
    private func countryFlag(countryCode: String) -> String {
        CountryCoordinates.flag(for: countryCode)
    }
}
