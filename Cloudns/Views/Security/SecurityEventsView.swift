import SwiftUI

struct SecurityEventsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SecurityEventsViewModel()
    @State private var searchText = ""
    
    private var displayedEvents: [SecurityEvent] {
        if searchText.isEmpty { return viewModel.events }
        return viewModel.events.filter {
            $0.clientIP.localizedCaseInsensitiveContains(searchText) ||
            $0.clientCountryName.localizedCaseInsensitiveContains(searchText) ||
            $0.action.localizedCaseInsensitiveContains(searchText) ||
            $0.host.localizedCaseInsensitiveContains(searchText) ||
            ($0.clientAsn ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(SecurityEvent.placeholders) { placeholderEvent in
                        SecurityEventCardView(event: placeholderEvent)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !displayedEvents.isEmpty {
                Section {
                    ForEach(displayedEvents) { event in
                        SecurityEventCardView(event: event)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search IP, Country or Action")
        .navigationTitle("Security Events")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.events.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchEvents(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.events.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "checkmark.shield",
                            title: "No Security Events",
                            message: "Your site hasn't blocked any threats recently. Everything is secure!"
                        )
                    )
                } else if displayedEvents.isEmpty && !searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: searchText,
                            clearAction: { searchText = "" }
                        )
                    )
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
