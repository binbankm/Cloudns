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
    @State private var recordToDelete: DNSRecord?
    @State private var showingSingleDeleteDialog = false
    @State private var showingBatchDeleteDialog = false
    
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
                        showingBatchDeleteDialog = true
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
             .higToast()
        }
        .sheet(isPresented: $showingPresetsSheet) {
            DNSPresetsSheetView(
                zoneName: zoneName,
                zoneId: zoneId,
                viewModel: viewModel
            )
             .higToast()
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
                        ToastManager.shared.showSuccess("BIND Records Imported", icon: "square.and.arrow.down.fill")
                        await viewModel.fetchRecords(isRefresh: true)
                    } catch {
                        ToastManager.shared.showError("Import Failed")
                    }
                }
            case .failure:
                ToastManager.shared.showError("Import Failed")
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
             .higToast()
        }
        .sheet(item: $recordToEdit) { record in
            DNSRecordFormView(viewModel: viewModel, existingRecord: record)
             .higToast()
        }
        .confirmationDialog(
            "Delete DNS Record",
            isPresented: $showingSingleDeleteDialog,
            titleVisibility: .visible
        ) {
            if let record = recordToDelete {
                Button("Delete \"\(record.name)\"", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteRecord(recordId: record.id)
                            ToastManager.shared.showSuccess("DNS Record Deleted", icon: "trash.fill")
                        } catch {
                            ToastManager.shared.showError("Failed to delete record")
                        }
                        recordToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                recordToDelete = nil
            }
        } message: {
            if let record = recordToDelete {
                Text("Are you sure you want to delete the \(record.type) record for \(record.name)? Traffic resolving to this record will stop immediately.")
            }
        }
        .confirmationDialog(
            "Delete Selected Records",
            isPresented: $showingBatchDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete \(multiSelection.count) Records", role: .destructive) {
                let count = multiSelection.count
                viewModel.deleteRecords(withIds: multiSelection)
                multiSelection.removeAll()
                editMode?.wrappedValue = .inactive
                ToastManager.shared.showSuccess("\(count) Records Deleted", icon: "trash.fill")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(multiSelection.count) DNS records? This action cannot be undone.")
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
                // SubMenu 1: Filter by Type
                Menu {
                    Button {
                        viewModel.selectedType = "ALL"
                        HIGFeedback.selection()
                    } label: {
                        if viewModel.selectedType == "ALL" {
                            Label("All Types", systemImage: "checkmark")
                        } else {
                            Text("All Types")
                        }
                    }
                    
                    Divider()
                    
                    ForEach(["A", "AAAA", "CNAME", "TXT", "MX", "NS", "PTR", "SRV", "CAA"], id: \.self) { type in
                        Button {
                            viewModel.selectedType = type
                            HIGFeedback.selection()
                        } label: {
                            if viewModel.selectedType == type {
                                Label(type, systemImage: "checkmark")
                            } else {
                                Text(type)
                            }
                        }
                    }
                } label: {
                    Label(
                        viewModel.selectedType == "ALL" ? "Record Type" : "Type: \(viewModel.selectedType)",
                        systemImage: "line.3.horizontal.decrease"
                    )
                }
                
                // SubMenu 2: Filter by Proxy Status
                Menu {
                    Button {
                        viewModel.selectedProxyStatus = "ALL"
                        HIGFeedback.selection()
                    } label: {
                        if viewModel.selectedProxyStatus == "ALL" {
                            Label("All Statuses", systemImage: "checkmark")
                        } else {
                            Text("All Statuses")
                        }
                    }
                    
                    Button {
                        viewModel.selectedProxyStatus = "PROXIED"
                        HIGFeedback.selection()
                    } label: {
                        if viewModel.selectedProxyStatus == "PROXIED" {
                            Label("Proxied (Orange Cloud)", systemImage: "checkmark")
                        } else {
                            Text("Proxied (Orange Cloud)")
                        }
                    }
                    
                    Button {
                        viewModel.selectedProxyStatus = "DNS_ONLY"
                        HIGFeedback.selection()
                    } label: {
                        if viewModel.selectedProxyStatus == "DNS_ONLY" {
                            Label("DNS Only (Grey Cloud)", systemImage: "checkmark")
                        } else {
                            Text("DNS Only (Grey Cloud)")
                        }
                    }
                } label: {
                    Label(
                        viewModel.selectedProxyStatus == "ALL" ? "Proxy Status" : (viewModel.selectedProxyStatus == "PROXIED" ? "Proxy: Proxied" : "Proxy: DNS Only"),
                        systemImage: "shield.lefthalf.filled"
                    )
                }
                
                // SubMenu 3: Sort Records
                Menu {
                    Button {
                        viewModel.sortOption = "name"
                        HIGFeedback.selection()
                    } label: {
                        if viewModel.sortOption == "name" {
                            Label("Name (A to Z)", systemImage: "checkmark")
                        } else {
                            Text("Name (A to Z)")
                        }
                    }
                    
                    Button {
                        viewModel.sortOption = "type"
                        HIGFeedback.selection()
                    } label: {
                        if viewModel.sortOption == "type" {
                            Label("Record Type", systemImage: "checkmark")
                        } else {
                            Text("Record Type")
                        }
                    }
                } label: {
                    Label("Sort Records", systemImage: "arrow.up.arrow.down")
                }
                
                if viewModel.isFiltered {
                    Divider()
                    
                    Button(role: .destructive) {
                        viewModel.resetFilters()
                        HIGFeedback.impact(.light)
                    } label: {
                        Label("Reset All Filters", systemImage: "arrow.counterclockwise")
                    }
                }
                
                Divider()
                
                // Tools & Presets Section
                Section("Tools") {
                    Button {
                        showingPresetsSheet = true
                    } label: {
                        Label("1-Click Presets", systemImage: "wand.and.stars")
                    }
                    
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
                }
            } label: {
                Image(systemName: viewModel.isFiltered ? "line.3.horizontal.decrease.circle.fill" : "ellipsis.circle")
                    .foregroundStyle(viewModel.isFiltered ? Color.orange : Color.accentColor)
            }
            .accessibilityLabel("DNS Options and Filters")
            
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
                recordToDelete = record
                showingSingleDeleteDialog = true
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
                ToastManager.shared.showCopied("Record Content Copied")
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
