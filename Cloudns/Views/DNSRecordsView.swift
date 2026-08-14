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
        if !viewModel.hasFetchedData {
            return DNSRecord.dummyData
        }
        return viewModel.records
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            List(selection: $multiSelection) {

                
                if let errorMessage = viewModel.errorMessage, viewModel.records.isEmpty && viewModel.hasFetchedData {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await viewModel.fetchRecords(isRefresh: true)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else if viewModel.records.isEmpty && viewModel.hasFetchedData {
                    EmptyStateView(
                        icon: "server.rack",
                        title: "No DNS Records",
                        message: "No DNS records found for this domain."
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else if displayRecords.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results",
                        message: "No records match your search."
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(displayRecords) { record in
                        DNSRecordCardView(record: record)
                            .tag(record.id)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        try? await viewModel.deleteRecord(recordId: record.id)
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
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    UIPasteboard.general.string = record.content ?? record.name
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                    }
                    .onDelete(perform: viewModel.deleteRecord)
                    
                    if viewModel.canLoadMore && viewModel.hasFetchedData {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .onAppear {
                                Task {
                                    await viewModel.fetchRecords()
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
            .disabled(!viewModel.hasFetchedData)
            .refreshable {
                await viewModel.fetchRecords(isRefresh: true)
            }
        }
        .navigationTitle("DNS Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
                    
                    Button(action: {
                        recordToEdit = nil
                        showingForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                if editMode?.wrappedValue.isEditing == true && !multiSelection.isEmpty {
                    Button(role: .destructive) {
                        let indicesToDelete = viewModel.records.enumerated().compactMap { (index, record) in
                            multiSelection.contains(record.id) ? index : nil
                        }
                        viewModel.deleteRecord(at: IndexSet(indicesToDelete))
                        multiSelection.removeAll()
                        editMode?.wrappedValue = .inactive
                    } label: {
                        Text("Delete Selected (\(multiSelection.count))")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) records" : "Search records")
        .fileExporter(isPresented: $showingExporter, document: TextDocument(url: exportedFileURL), contentType: .plainText, defaultFilename: "dns_records_\(zoneName).txt") { result in
            // Handle export result if needed
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.plainText, .data]) { result in
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
        .task {
            if viewModel.records.isEmpty {
                await viewModel.fetchRecords()
            }
        }
        .onChange(of: editMode?.wrappedValue) { newValue in
            // Always clear selection when entering or exiting edit mode
            multiSelection.removeAll()
        }
        .sheet(isPresented: $showingForm) {
            DNSRecordFormView(viewModel: viewModel, existingRecord: nil)
        }
        .sheet(item: $recordToEdit) { record in
            DNSRecordFormView(viewModel: viewModel, existingRecord: record)
        }
    }
}

struct DNSRecordCardView: View {
    let record: DNSRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                // Record Type Badge
                Text(record.type)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .frame(width: 44)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
                // Record Name
                Text(record.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Proxy Status Icon (Orange/Gray Cloud)
                if record.proxiable == true {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 14))
                        .foregroundColor(record.proxied == true ? .orange : .gray)
                } else {
                    Text("DNS Only")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            HStack {
                Text(record.content ?? (record.data != nil ? "Advanced Record Data" : "No content"))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                Text(record.ttl == 1 ? "Auto" : "\(record.ttl)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let comment = record.comment, !comment.isEmpty {
                Text(comment)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
