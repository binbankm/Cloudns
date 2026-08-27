import SwiftUI

struct WorkerTailView: View {
    // MARK: - Properties
    let accountId: String
    let scriptName: String
    
    @StateObject private var viewModel: WorkerTailViewModel
    @State private var autoScroll = true
    @State private var selectedEvent: TailTraceItem?
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerTailViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search logs & URLs"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(CloudnsColor.secondaryGroupedBackground)
            
            // Top Toolbar: Status & Filters
            filterBar
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(CloudnsColor.secondaryGroupedBackground)
            
            Divider()
            
            // Console Logs Stream
            if viewModel.events.isEmpty {
                emptyState
            } else {
                ScrollViewReader { _ in
                    List {
                        ForEach(viewModel.filteredEvents) { item in
                            Button {
                                HapticManager.impact(.light)
                                selectedEvent = item
                            } label: {
                                TailEventRowView(item: item)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(Color(.systemBackground))
                        }
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.interactively)
                    .centerConstrainedWidth(maxWidth: 840)
                }
            }
        }
        .navigationTitle("Live Tail Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        HapticManager.impact(.light)
                        viewModel.clearLogs()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear logs")
                    .disabled(viewModel.events.isEmpty)
                    
                    Button {
                        HapticManager.impact(.light)
                        if viewModel.isStreaming {
                            viewModel.stopStream()
                        } else {
                            Task { await viewModel.startStream() }
                        }
                    } label: {
                        Image(systemName: viewModel.isStreaming ? "pause.fill" : "play.fill")
                            .foregroundStyle(viewModel.isStreaming ? .orange : .green)
                    }
                    .accessibilityLabel(viewModel.isStreaming ? "Pause stream" : "Resume stream")
                }
            }
        }
        .task {
            await viewModel.startStream()
        }
        .onDisappear {
            viewModel.stopStream()
        }
        .sheet(item: $selectedEvent) { event in
            TailEventDetailSheetView(event: event)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Private Views
    private var filterBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isStreaming ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(viewModel.isStreaming ? "Connected" : "Paused")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.isStreaming ? .green : .secondary)
            }
            
            Spacer()
            
            Picker("Filter", selection: $viewModel.selectedFilter) {
                Text("All (\(viewModel.events.count))").tag(0)
                Text("Logs").tag(1)
                Text("Exceptions").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 220)
            .onChange(of: viewModel.selectedFilter) { _ in
                HapticManager.impact(.light)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            if viewModel.isStreaming {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Listening for live worker events…")
                    .font(.body.weight(.medium))
                Text("Send an HTTP request or wait for a cron trigger to see logs appear in real time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Image(systemName: "pause.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("Log stream paused")
                    .font(.body.weight(.medium))
                Button("Resume Stream") {
                    HapticManager.impact(.light)
                    Task { await viewModel.startStream() }
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CloudnsColor.groupedBackground)
    }
}
