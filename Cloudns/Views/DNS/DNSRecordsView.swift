import SwiftUI
import UniformTypeIdentifiers

struct DNSRecordsView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: DNSRecordsViewModel
    @State private var showingForm = false
    @State private var recordToEdit: DNSRecord? = nil
    
    // Export/Import/Edit states
    @State private var showingExporter = false
    @State private var exportedFileURL: URL? = nil
    @State private var showingImporter = false
    @State private var multiSelection = Set<String>()
    
    @Environment(\.editMode) private var editMode
    
    init(zoneId: String, zoneName: String) {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: DNSRecordsViewModel(zoneId: zoneId))
    }
    
    var displayRecords: [DNSRecord] {
        viewModel.records
    }
    
    var body: some View {
        List(selection: $multiSelection) {
            if !displayRecords.isEmpty {
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
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("DNS Records")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchQuery,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) records" : "Search records"
        )
        .refreshable {
            await viewModel.fetchRecords(isRefresh: true)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
        .fileExporter(
            isPresented: $showingExporter,
            document: TextDocument(url: exportedFileURL),
            contentType: .plainText,
            defaultFilename: "dns_records_\(zoneName).txt"
        ) { _ in }
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
                print("Import failed: \(error.localizedDescription)")
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.records.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchRecords(isRefresh: true) }
                            }
                        )
                    )
                } else if viewModel.records.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "server.rack",
                            title: "No DNS Records",
                            message: "No DNS records found for this domain.",
                            actionTitle: "Add Record",
                            action: { showingForm = true }
                        )
                    )
                } else if displayRecords.isEmpty && !viewModel.searchQuery.isEmpty {
                    StateOverlayView(
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
                    Task {
                        if let url = try? await viewModel.exportRecords() {
                            self.exportedFileURL = url
                            self.showingExporter = true
                        }
                    }
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
        DNSRecordRowView(record: record)
            .tag(record.id)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    HapticManager.impact(.medium)
                    Task {
                        do {
                            try await viewModel.deleteRecord(recordId: record.id)
                            ToastManager.shared.showSuccess("DNS Record Deleted", message: "\(record.name) (\(record.type))")
                        } catch {
                            ToastManager.shared.showError("Failed to delete record", message: error.localizedDescription)
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
                    ToastManager.shared.showCopied("Record content copied")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .tint(.blue)
            }
    }
}

struct DNSRecordRowView: View {
    let record: DNSRecord
    
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                // Record Type Badge
                Text(record.type)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .frame(width: 48)
                    .padding(.vertical, 3)
                    .background(recordTypeColor.opacity(0.14))
                    .foregroundStyle(recordTypeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                // Record Name
                Text(record.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Proxy Status Badge
                if record.proxiable == true {
                    CloudnsBadge(
                        record.proxied == true ? .proxied("Proxied") : .dnsOnly("DNS Only"),
                        isCompact: true
                    )
                } else {
                    CloudnsBadge(.dnsOnly("DNS Only"), isCompact: true)
                }
            }
            
            HStack(alignment: .top) {
                Text(record.content ?? (record.data != nil ? "Advanced Record Data" : "No content"))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                Text(record.ttl == 1 ? "Auto" : "\(record.ttl)s")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            
            if let comment = record.comment, !comment.isEmpty {
                Text(comment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.type) record \(record.name), points to \(record.content ?? ""), \(record.proxied == true ? "Proxied" : "DNS Only")")
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        // Not used for exporting
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if let url = url {
            return try FileWrapper(url: url)
        }
        return FileWrapper(regularFileWithContents: Data())
    }
}
