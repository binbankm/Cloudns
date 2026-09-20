import SwiftUI
import UniformTypeIdentifiers

// MARK: - DNSRecordsView

// Apple HIG Compliant DNS Record Management (iOS 16.0+)

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
        recordsList
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search Records"
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
                    bottomBar
                }
            }
            .modifier(DNSRecordsSheetsModifier(
                zoneName: zoneName,
                zoneId: zoneId,
                showingExportSheet: $showingExportSheet,
                showingPresetsSheet: $showingPresetsSheet,
                showingImporter: $showingImporter,
                showingForm: $showingForm,
                recordToEdit: $recordToEdit,
                viewModel: viewModel
            ))
            .modifier(DNSRecordsDialogsModifier(
                showingSingleDeleteDialog: $showingSingleDeleteDialog,
                showingBatchDeleteDialog: $showingBatchDeleteDialog,
                recordToDelete: $recordToDelete,
                multiSelection: $multiSelection,
                editMode: editMode,
                viewModel: viewModel
            ))
            .listState(
                isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
                loadingMessage: "Loading DNS Records…",
                error: viewModel.records.isEmpty ? viewModel.errorMessage : nil,
                isEmpty: viewModel.hasFetchedData && viewModel.records.isEmpty,
                empty: .init(
                    title: "No DNS Records",
                    systemImage: "list.bullet.rectangle",
                    description: "No DNS records found in this zone. Add A, CNAME, or MX records to start routing traffic.",
                    actionTitle: "Add Record",
                    action: { showingForm = true }
                ),
                searchQuery: (viewModel.hasFetchedData && displayRecords.isEmpty && !viewModel.searchQuery.isEmpty) ? viewModel.searchQuery : nil,
                onRetry: { Task { await viewModel.fetchRecords(isRefresh: true) } }
            )
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchRecords()
                }
            }
    }

    private var recordsList: some View {
        List(selection: $multiSelection) {
            if !displayRecords.isEmpty {
                recordsSections

                if viewModel.canLoadMore, viewModel.hasFetchedData {
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
    }

    @ViewBuilder
    private var bottomBar: some View {
        let isEditing = editMode?.wrappedValue.isEditing ?? false
        if isEditing, !multiSelection.isEmpty {
            let selectedCount = multiSelection.count
            Button(role: .destructive) {
                HapticManager.impact(.medium)
                showingBatchDeleteDialog = true
            } label: {
                Text("Delete Selected (\(selectedCount))")
                    .foregroundStyle(.red)
            }
            .tint(.red)
        }
    }

    // MARK: - Subviews

    private var trailingToolbar: some View {
        HStack(spacing: 8) {
            Menu {
                // SubMenu 1: Filter by Type
                Menu {
                    Button {
                        viewModel.selectedType = "ALL"
                        HapticManager.selection()
                    } label: {
                        if viewModel.selectedType == "ALL" {
                            Label("All Types", systemImage: "checkmark")
                        } else {
                            Text("All Types")
                        }
                    }

                    Divider()

                    ForEach(DNSRecordsViewModel.supportedRecordTypes, id: \.self) { type in
                        Button {
                            viewModel.selectedType = type
                            HapticManager.selection()
                        } label: {
                            if viewModel.selectedType == type {
                                Label(type, systemImage: "checkmark")
                            } else {
                                Text(type)
                            }
                        }
                    }
                } label: {
                    Label {
                        if viewModel.selectedType == "ALL" {
                            Text("Record Type")
                        } else {
                            Text("Type: \(viewModel.selectedType)")
                        }
                    } icon: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }

                Menu {
                    ForEach(DNSProxyFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.selectedProxyFilter = filter
                            HapticManager.selection()
                        } label: {
                            if viewModel.selectedProxyFilter == filter {
                                Label(filter.displayName, systemImage: "checkmark")
                            } else {
                                Text(filter.displayName)
                            }
                        }
                    }
                } label: {
                    Label {
                        if viewModel.selectedProxyFilter == .all {
                            Text("Proxy Status")
                        } else {
                            Text("Proxy: \(viewModel.selectedProxyFilter.displayName)")
                        }
                    } icon: {
                        Image(systemName: "shield.lefthalf.filled")
                    }
                }

                // SubMenu 3: Sort Records
                Menu {
                    ForEach(DNSSortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                            HapticManager.selection()
                        } label: {
                            if viewModel.sortOption == option {
                                Label(option.displayName, systemImage: "checkmark")
                            } else {
                                Text(option.displayName)
                            }
                        }
                    }
                } label: {
                    Label("Sort Records", systemImage: "arrow.up.arrow.down")
                }

                if viewModel.isFiltered {
                    Divider()

                    Button(role: .destructive) {
                        viewModel.resetFilters()
                        HapticManager.impact(.light)
                    } label: {
                        Label("Reset All Filters", systemImage: "arrow.counterclockwise")
                    }
                    .tint(.red)
                }

                Divider()

                // Tools & Presets Section
                Section("Tools") {
                    Button {
                        Task {
                            HapticManager.selection()
                            ToastManager.shared.showSuccess("Scanning DNS Records…", icon: "antenna.radiowaves.left.and.right")
                            if let added = await viewModel.scanRecords() {
                                ToastManager.shared.showSuccess(added > 0 ? "\(added) Records Added" : "Scan Complete", icon: "checkmark.circle.fill")
                                HapticManager.notification(.success)
                            } else {
                                ToastManager.shared.showError("DNS Scan Failed")
                                HapticManager.notification(.error)
                            }
                        }
                    } label: {
                        Label("Scan DNS Records", systemImage: "antenna.radiowaves.left.and.right")
                    }

                    Button {
                        showingPresetsSheet = true
                    } label: {
                        Label("DNS Presets", systemImage: "wand.and.stars")
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
            }
            .accessibilityLabel(viewModel.isFiltered ? Text("DNS Options (Filtered)") : Text("DNS Options and Filters"))

            Button {
                showingForm = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add DNS Record")
            .keyboardShortcut("n", modifiers: .command)
        }
    }

    private var groupedRecordTypes: [String] {
        viewModel.groupedRecordTypes
    }

    private func records(for type: String) -> [DNSRecord] {
        viewModel.records(for: type)
    }

    @ViewBuilder
    private var recordsSections: some View {
        if viewModel.searchQuery.isEmpty {
            ForEach(groupedRecordTypes, id: \.self) { type in
                let items = records(for: type)
                Section(header: Text("\(type) Records (\(items.count))")) {
                    ForEach(items) { record in
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
                            Task {
                                if let newProxied = await viewModel.toggleProxy(for: record) {
                                    HapticManager.impact(.medium)
                                    ToastManager.shared.showSuccess(
                                        newProxied
                                            ? "Proxy Enabled (Orange Cloud ☁️)"
                                            : "Proxy Disabled (DNS Only)",
                                        icon: "shield.lefthalf.filled"
                                    )
                                } else {
                                    HapticManager.notification(.error)
                                    ToastManager.shared.showError("Failed to Update Proxy Status")
                                }
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .contextMenu {
            Button {
                copyToClipboard(record.content ?? record.name, toast: "Record Content Copied")
            } label: {
                Label("Copy Content", systemImage: "doc.on.doc")
            }

            Button {
                copyToClipboard(record.name, toast: "Record Name Copied")
            } label: {
                Label("Copy Name", systemImage: "character.textbox")
            }

            if record.proxiable == true {
                Button {
                    Task {
                        if let newProxied = await viewModel.toggleProxy(for: record) {
                            HapticManager.impact(.medium)
                            ToastManager.shared.showSuccess(
                                newProxied
                                    ? "Proxy Enabled (Orange Cloud ☁️)"
                                    : "Proxy Disabled (DNS Only)",
                                icon: "shield.lefthalf.filled"
                            )
                        } else {
                            HapticManager.notification(.error)
                            ToastManager.shared.showError("Failed to Update Proxy Status")
                        }
                    }
                } label: {
                    Label(
                        record.proxied == true ? "Switch to DNS Only" : "Enable Cloudflare Proxy",
                        systemImage: record.proxied == true ? "cloud" : "cloud.fill"
                    )
                }
            }

            Button {
                recordToEdit = record
            } label: {
                Label("Edit Record", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                recordToDelete = record
                showingSingleDeleteDialog = true
            } label: {
                Label("Delete Record", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                recordToDelete = record
                showingSingleDeleteDialog = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)

            Button {
                recordToEdit = record
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(ThemeManager.shared.accentColor)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                copyToClipboard(record.content ?? record.name, toast: "Record Content Copied")
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
}

// MARK: - DNSRecordRowView

struct DNSRecordRowView: View {
    let record: DNSRecord
    var onToggleProxy: (() -> Void)?

    private var recordTypeColor: Color {
        switch record.type.uppercased() {
        case "A", "AAAA": .blue
        case "CNAME": .green
        case "TXT": .purple
        case "MX": .orange
        case "NS", "CAA", "SRV": .teal
        default: .indigo
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Text(verbatim: record.type)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .frame(width: 48)
                    .padding(.vertical, 3)
                    .background(recordTypeColor.opacity(0.14))
                    .foregroundStyle(recordTypeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(verbatim: record.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if record.proxiable == true {
                    Button {
                        HapticManager.selection()
                        onToggleProxy?()
                    } label: {
                        proxyBadge
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(record.proxied == true ? Text("Cloudflare Proxy Enabled") : Text("Cloudflare Proxy Disabled"))
                    .accessibilityHint("Double tap to toggle proxy status between Proxied and DNS Only")
                } else {
                    dnsOnlyBadge
                }
            }

            HStack(alignment: .top) {
                Text(record.content ?? (record.data != nil ? String(localized: "Advanced Record Data") : String(localized: "No content")))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                Text(record.ttl == 1 ? LocalizedStringKey("Auto") : "\(record.ttl)s")
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
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 1)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var proxyBadge: some View {
        if record.proxied == true {
            HStack(spacing: 4) {
                Image(systemName: "cloud.fill")
                    .font(.caption2)
                Text("Proxied")
                    .font(.caption2.weight(.medium))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.14))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
        } else {
            dnsOnlyBadge
        }
    }

    private var dnsOnlyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "cloud")
                .font(.caption2)
            Text("DNS Only")
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.12))
        .foregroundStyle(.secondary)
        .clipShape(Capsule())
    }
}

// MARK: - Modifiers

private struct DNSRecordsSheetsModifier: ViewModifier {
    let zoneName: String
    let zoneId: String
    @Binding var showingExportSheet: Bool
    @Binding var showingPresetsSheet: Bool
    @Binding var showingImporter: Bool
    @Binding var showingForm: Bool
    @Binding var recordToEdit: DNSRecord?
    @ObservedObject var viewModel: DNSRecordsViewModel

    func body(content: Content) -> some View {
        content
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
                allowedContentTypes: [.plainText, UTType(filenameExtension: "txt") ?? .plainText, UTType(filenameExtension: "zone") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .sheet(isPresented: $showingForm) {
                DNSRecordFormView(viewModel: viewModel)
            }
            .sheet(item: $recordToEdit) { record in
                DNSRecordFormView(viewModel: viewModel, existingRecord: record)
            }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                ToastManager.shared.showError("Access Denied")
                return
            }
            Task {
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    try await viewModel.importRecords(fileURL: url)
                    ToastManager.shared.showSuccess("Records Imported Successfully", icon: "square.and.arrow.down.fill")
                } catch {
                    ToastManager.shared.showError("Import Failed")
                }
            }
        case .failure:
            ToastManager.shared.showError("Import Failed")
        }
    }
}

private struct DNSRecordsDialogsModifier: ViewModifier {
    @Binding var showingSingleDeleteDialog: Bool
    @Binding var showingBatchDeleteDialog: Bool
    @Binding var recordToDelete: DNSRecord?
    @Binding var multiSelection: Set<String>
    var editMode: Binding<EditMode>?
    @ObservedObject var viewModel: DNSRecordsViewModel

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Delete DNS Record",
                isPresented: $showingSingleDeleteDialog,
                titleVisibility: .visible
            ) {
                if let record = recordToDelete {
                    Button("Delete \"\(record.name)\"", role: .destructive) {
                        deleteRecord(record)
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
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \(multiSelection.count) DNS records? This action cannot be undone.")
            }
    }

    private func deleteRecord(_ record: DNSRecord) {
        Task {
            do {
                try await viewModel.deleteRecord(recordId: record.id)
                ToastManager.shared.showSuccess("DNS Record Deleted", icon: "trash.fill")
            } catch {
                ToastManager.shared.showError("Failed to Delete Record")
            }
            recordToDelete = nil
        }
    }
}
