import SwiftUI
import UniformTypeIdentifiers

// MARK: - DNSRecordsView

struct DNSRecordsView: View {
    // MARK: - Properties
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: DNSRecordsViewModel
    @State private var showingForm = false
    @State private var recordToEdit: DNSRecord?
    
    // Export / Import / Presets states
    @State private var showingExportSheet = false
    @State private var showingImporter = false
    @State private var showingPresetsSheet = false
    @State private var multiSelection = Set<String>()
    
    @Environment(\.editMode) private var editMode
    
    init(zoneId: String, zoneName: String) {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: DNSRecordsViewModel(zoneId: zoneId))
    }
    
    var displayRecords: [DNSRecord] {
        viewModel.filteredRecords
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchQuery,
                prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) records" : "Search records"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            List(selection: $multiSelection) {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(DNSRecord.placeholders) { placeholderRecord in
                            DNSRecordRowView(record: placeholderRecord)
                        }
                    }
                    .skeletonLoading(true)
                } else if !displayRecords.isEmpty {
                    recordsSections

                    if viewModel.canLoadMore && viewModel.hasFetchedData {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .onAppear {
                                Task {
                                    await viewModel.fetchRecords()
                                }
                            }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
        .navigationTitle("DNS Records")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchRecords(isRefresh: true)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                trailingToolbar
            }
            
            ToolbarItem(placement: .bottomBar) {
                if editMode?.wrappedValue.isEditing == true && !multiSelection.isEmpty {
                    Button(role: .destructive) {
                        HapticManager.impact(.medium)
                        viewModel.deleteRecords(withIds: multiSelection)
                        multiSelection.removeAll()
                        editMode?.wrappedValue = .inactive
                    } label: {
                        Text("Delete Selected (\(multiSelection.count))")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            DNSExportSheetView(
                zoneName: zoneName,
                zoneId: zoneId,
                records: viewModel.records,
                viewModel: viewModel
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPresetsSheet) {
            DNSPresetsSheetView(
                zoneName: zoneName,
                zoneId: zoneId,
                viewModel: viewModel
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.plainText, .data]
        ) { result in
            switch result {
            case .success(let fileURL):
                Task {
                    _ = fileURL.startAccessingSecurityScopedResource()
                    try? await viewModel.importRecords(fileURL: fileURL)
                    fileURL.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                CloudnsToastManager.shared.showError("Import Failed", message: error.localizedDescription)
            }
        }
        .onChange(of: editMode?.wrappedValue) { _ in
            multiSelection.removeAll()
        }
        .sheet(isPresented: $showingForm) {
            DNSRecordFormView(viewModel: viewModel, existingRecord: nil)
        }
        .sheet(item: $recordToEdit) { record in
            DNSRecordFormView(viewModel: viewModel, existingRecord: record)
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.records.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchRecords(isRefresh: true) }
                            }
                        )
                    )
                } else if viewModel.records.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "server.rack",
                            title: "No DNS Records",
                            message: "No DNS records found for this domain.",
                            actionTitle: "Add Record",
                            action: { showingForm = true }
                        )
                    )
                } else if displayRecords.isEmpty && !viewModel.searchQuery.isEmpty {
                    CloudnsStateOverlayView(
                        state: .search(
                            query: viewModel.searchQuery,
                            clearAction: { viewModel.searchQuery = "" }
                        )
                    )
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRecords()
            }
        }
    }
    
    @ViewBuilder
    // MARK: - Private Views
    private var recordsSections: some View {
        if viewModel.sortOption == "type" {
            let groupedRecords = Dictionary(grouping: displayRecords, by: { $0.type })
            let sortedTypes = groupedRecords.keys.sorted()
            ForEach(sortedTypes, id: \.self) { type in
                Section(header: Text(type).font(.subheadline)) {
                    ForEach(groupedRecords[type] ?? []) { record in
                        recordRow(record: record)
                    }
                }
            }
        } else if viewModel.sortOption == "proxied" {
            let groupedRecords = Dictionary(grouping: displayRecords, by: { $0.proxied == true ? "Proxied (Cloudflare)" : "DNS Only" })
            let sortedKeys = groupedRecords.keys.sorted(by: { $0 > $1 })
            ForEach(sortedKeys, id: \.self) { status in
                Section(header: Text(status).font(.subheadline)) {
                    ForEach(groupedRecords[status] ?? []) { record in
                        recordRow(record: record)
                    }
                }
            }
        } else {
            Section {
                ForEach(displayRecords) { record in
                    recordRow(record: record)
                }
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolbar: some View {
        HStack {
            EditButton()
            
            Menu {
                Picker("Sort By", selection: $viewModel.sortOption) {
                    Text("Name").tag("name")
                    Text("Type").tag("type")
                    Text("Proxied").tag("proxied")
                    Text("Content").tag("content")
                }
                
                Divider()
                
                Button {
                    showingPresetsSheet = true
                } label: {
                    Label("1-Click Presets", systemImage: "wand.and.stars")
                }
                
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export Records", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingImporter = true
                } label: {
                    Label("Import BIND File", systemImage: "square.and.arrow.down")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More Options")
            
            Button(action: {
                recordToEdit = nil
                showingForm = true
            }) {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add DNS Record")
        }
    }
    
    @ViewBuilder
    private func recordRow(record: DNSRecord) -> some View {
        Group {
            if editMode?.wrappedValue.isEditing == true {
                DNSRecordRowView(
                    record: record,
                    onToggleProxy: {
                        Task { await viewModel.toggleProxy(for: record) }
                    }
                )
                .tag(record.id)
            } else {
                Button {
                    recordToEdit = record
                } label: {
                    DNSRecordRowView(
                        record: record,
                        onToggleProxy: {
                            Task { await viewModel.toggleProxy(for: record) }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HapticManager.impact(.medium)
                Task {
                    do {
                        try await viewModel.deleteRecord(recordId: record.id)
                        CloudnsToastManager.shared.showSuccess("DNS Record Deleted", message: "\(record.name) (\(record.type))")
                    } catch {
                        CloudnsToastManager.shared.showError("Failed to delete record", message: error.localizedDescription)
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                recordToEdit = record
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                UIPasteboard.general.string = record.content ?? record.name
                HapticManager.impact(.light)
                CloudnsToastManager.shared.showCopied("Record content copied")
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
}
