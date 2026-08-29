import SwiftUI

// MARK: - SecurityEventsView

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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(SecurityEvent.placeholders) { placeholderEvent in
                        SecurityEventCardView(event: placeholderEvent)
                    }
                }
                .redacted(reason: .placeholder)
            } else if !displayedEvents.isEmpty {
                Section {
                    ForEach(displayedEvents) { event in
                        SecurityEventCardView(event: event)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search IP, Country or Action"
        )
        .navigationTitle("Security Events")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.events.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchEvents(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.events.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Security Events",
                            systemImage: "checkmark.shield",
                            description: "Your site hasn't blocked any threats recently. Everything is secure!"
                        )
                    )
                } else if displayedEvents.isEmpty && !searchText.isEmpty {
                    HIGContentState(.search(query: searchText))
                }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HIGBadge(.custom(color: colorForAction(event.action), text: actionDisplayName(event.action)), isCompact: true)
                
                Spacer()
                
                Text(formatDate(event.datetime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("IP Address")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(countryFlag(countryCode: event.clientCountryName))
                        Text(event.clientIP)
                            .font(.subheadline.monospacedDigit())
                    }
                }
                
                Spacer()
                
                if let asn = event.clientAsn {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ASN")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("AS\(asn)")
                            .font(.subheadline)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Source / Engine")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(event.source.capitalized)
                    .font(.footnote)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Target URL")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(event.host)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
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
        case "block", "connectionClose": return .red
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "log": return .blue
        default: return .gray
        }
    }
    
    private func countryFlag(countryCode: String) -> String {
        CountryCoordinates.flag(for: countryCode)
    }
    
    private func formatDate(_ isoString: String) -> String {
        DateFormatters.formatISO8601ToDisplay(isoString, style: DateFormatters.mediumDateTime)
    }
}
