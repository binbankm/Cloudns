import SwiftUI
import UniformTypeIdentifiers

// MARK: - DNSRecordsView

struct DNSRecordsView: View {
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
    
    var body: some View {
        List(selection: $multiSelection) {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                skeletonSection
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
        .searchable(
            text: $viewModel.searchQuery,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) records" : "Search records"
        )
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
                let isEditing = editMode?.wrappedValue.isEditing ?? false
                if isEditing && !multiSelection.isEmpty {
                    let selectedCount = multiSelection.count
                    Button(role: .destructive) {
                        HIGFeedback.impact(.medium)
                        viewModel.deleteRecords(withIds: multiSelection)
                        multiSelection.removeAll()
                        editMode?.wrappedValue = .inactive
                    } label: {
                        Text("Delete Selected (\(selectedCount))")
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
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                guard selectedURL.startAccessingSecurityScopedResource() else { return }
                defer { selectedURL.stopAccessingSecurityScopedResource() }
                
                Task {
                    do {
                        try await DNSService.shared.importDNSRecords(zoneId: zoneId, fileURL: selectedURL)
                        HIGFeedback.success()
                        await viewModel.fetchRecords(isRefresh: true)
                    } catch {
                        HIGFeedback.error()
                    }
                }
            case .failure:
                HIGFeedback.error()
            }
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.records.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchRecords(isRefresh: true) }
                            }
                        )
                    )
                } else if viewModel.records.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No DNS Records",
                            systemImage: "server.rack",
                            description: "No DNS records found in this zone. Add A, CNAME, or MX records to start routing traffic.",
                            actionTitle: "Add Record",
                            action: { showingForm = true }
                        )
                    )
                } else if displayRecords.isEmpty && !viewModel.searchQuery.isEmpty {
                    HIGContentState(.search(query: viewModel.searchQuery))
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            DNSRecordFormView(viewModel: viewModel)
        }
        .sheet(item: $recordToEdit) { record in
            DNSRecordFormView(viewModel: viewModel, existingRecord: record)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRecords()
            }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var trailingToolbar: some View {
        HStack(spacing: 8) {
            Menu {
                Button {
                    showingForm = true
                } label: {
                    Label("Add DNS Record", systemImage: "plus")
                }
                
                Button {
                    showingPresetsSheet = true
                } label: {
                    Label("1-Click Presets", systemImage: "wand.and.stars")
                }
                
                Divider()
                
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export BIND Zone File", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingImporter = true
                } label: {
                    Label("Import BIND Zone File", systemImage: "square.and.arrow.down")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            
            Button {
                showingForm = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add DNS Record")
        }
    }
    
    @ViewBuilder
    private var skeletonSection: some View {
        Section {
            ForEach(DNSRecord.placeholders) { (placeholderRecord: DNSRecord) in
                DNSRecordRowView(record: placeholderRecord)
            }
        }
        .redacted(reason: .placeholder)
    }
    
    @ViewBuilder
    private var recordsSections: some View {
        if viewModel.searchQuery.isEmpty {
            let grouped = Dictionary(grouping: displayRecords, by: { $0.type })
            let sortedTypes = grouped.keys.sorted()
            
            ForEach(sortedTypes, id: \.self) { type in
                Section(header: Text("\(type) Records (\(grouped[type]?.count ?? 0))")) {
                    ForEach(grouped[type] ?? []) { record in
                        recordRow(record)
                    }
                }
            }
        } else {
            Section(header: Text("Matching Records (\(displayRecords.count))")) {
                ForEach(displayRecords) { record in
                    recordRow(record)
                }
            }
        }
    }
    
    @ViewBuilder
    private func recordRow(_ record: DNSRecord) -> some View {
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
                HIGFeedback.impact(.medium)
                Task {
                    do {
                        try await viewModel.deleteRecord(recordId: record.id)
                    } catch {
                        HIGFeedback.error()
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
                HIGFeedback.success()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
}

// MARK: - DNSRecordRowView (Inlined & Cohesive)

struct DNSRecordRowView: View {
    let record: DNSRecord
    var onToggleProxy: (() -> Void)?
    
    private var recordTypeColor: Color {
        switch record.type.uppercased() {
        case "A", "AAAA": return .blue
        case "CNAME": return .green
        case "TXT": return .purple
        case "MX": return .orange
        case "NS", "CAA", "SRV": return .teal
        default: return .indigo
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Text(record.type)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .frame(width: 48)
                    .padding(.vertical, 2.5)
                    .background(recordTypeColor.opacity(0.14))
                    .foregroundStyle(recordTypeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                Text(record.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                if record.proxiable == true {
                    Button {
                        HIGFeedback.selection()
                        onToggleProxy?()
                    } label: {
                        HIGBadge(
                            record.proxied == true ? .proxied : .dnsOnly,
                            isCompact: true
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    HIGBadge(.dnsOnly, isCompact: true)
                }
            }
            
            HStack(alignment: .top) {
                Text(record.content ?? (record.data != nil ? "Advanced Record Data" : "No content"))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                Text(record.ttl == 1 ? "Auto" : "\(record.ttl)s")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            if let comment = record.comment, !comment.isEmpty {
                Text(comment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 1)
            }
            
            if let tags = record.tags, !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 1)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}
