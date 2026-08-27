import SwiftUI

struct SecurityEventsView: View {
    // MARK: - Properties
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
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $searchText,
                prompt: "Search IP, Country or Action"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(SecurityEvent.placeholders) { placeholderEvent in
                            SecurityEventCardView(event: placeholderEvent)
                        }
                    }
                    .skeletonLoading(true)
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
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
        .navigationTitle("Security Events")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.events.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchEvents(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.events.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "checkmark.shield",
                            title: "No Security Events",
                            message: "Your site hasn't blocked any threats recently. Everything is secure!"
                        )
                    )
                } else if displayedEvents.isEmpty && !searchText.isEmpty {
                    CloudnsStateOverlayView(
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
