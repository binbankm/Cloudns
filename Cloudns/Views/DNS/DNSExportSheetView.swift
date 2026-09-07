import SwiftUI
import UniformTypeIdentifiers

// MARK: - TextDocument (FileDocument for Export)

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

// MARK: - DNSExportSheetView
// Apple HIG Compliant DNS Zone File Exporter (iOS 16+ ShareLink Integrated)

struct DNSExportSheetView: View {
    let zoneName: String
    let zoneId: String
    let records: [DNSRecord]
    @ObservedObject var viewModel: DNSRecordsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportedContent: String = ""
    @State private var exportedFileURL: URL?
    @State private var isLoading = true
    @State private var showingFileExporter = false
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var accentColor: Color {
        themeManager.currentColor.color
    }
    
    private var contentLines: [String] {
        exportedContent.components(separatedBy: "\n")
    }
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Generating BIND Zone File…")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 24)
                    }
                } else {
                    // MARK: - Summary Section
                    Section(header: Text("Zone File Summary")) {
                        LabeledContent {
                            Text("\(records.count) Records")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.14))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        } label: {
                            Label("Zone Name", systemImage: "globe")
                        }
                        
                        LabeledContent("Format", value: "BIND RFC 1035")
                    }
                    
                    // MARK: - Export Actions
                    Section(header: Text("Actions")) {
                        Button {
                            copyToClipboard(exportedContent, toast: "BIND Zone File Copied")
                        } label: {
                            Label("Copy All Records", systemImage: "doc.on.doc")
                                .foregroundStyle(accentColor)
                        }
                        
                        if let url = exportedFileURL {
                            ShareLink(
                                item: url,
                                subject: Text("\(zoneName) DNS Zone File"),
                                message: Text("Cloudflare BIND zone file exported via Cloudns")
                            ) {
                                Label("Share Zone File", systemImage: "square.and.arrow.up")
                                    .foregroundStyle(accentColor)
                            }
                        }
                        
                        Button {
                            HapticManager.impact(.light)
                            showingFileExporter = true
                        } label: {
                            Label("Save to Files", systemImage: "folder")
                                .foregroundStyle(accentColor)
                        }
                    }
                    
                    // MARK: - Zone File Content Preview
                    Section(
                        header: HStack {
                            Text("Zone File Content")
                            Spacer()
                            Text("\(contentLines.count) lines")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        },
                        footer: Text("Standard RFC 1035 format. Text wraps naturally without horizontal overflow.")
                    ) {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(contentLines.enumerated()), id: \.offset) { idx, line in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(idx + 1)")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(Color(.tertiaryLabel))
                                            .frame(width: 24, alignment: .trailing)
                                        
                                        Text(verbatim: line)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(lineColor(for: line))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 300)
                        .textSelection(.enabled)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Export Zone File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor)
                }
            }
            .task {
                await loadExportedContent()
            }
            .fileExporter(
                isPresented: $showingFileExporter,
                document: TextDocument(url: exportedFileURL),
                contentType: .plainText,
                defaultFilename: "\(zoneName).txt"
            ) { result in
                switch result {
                case .success:
                    ToastManager.shared.showSuccess("Zone File Saved", icon: "folder.fill")
                    HapticManager.notification(.success)
                case .failure:
                    ToastManager.shared.showError("Failed to Save File")
                    HapticManager.notification(.error)
                }
            }
        }
    }
    
    private func lineColor(for line: String) -> Color {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix(";") {
            return .secondary
        } else if trimmed.hasPrefix("$") {
            return .purple
        } else if trimmed.contains(" IN ") {
            return .primary
        }
        return .primary
    }
    
    private func loadExportedContent() async {
        isLoading = true
        do {
            let fileURL = try await DNSService.shared.exportDNSRecords(zoneId: zoneId)
            let content = (try? String(contentsOf: fileURL, encoding: String.Encoding.utf8)) ?? ""
            exportedContent = content
            exportedFileURL = fileURL
        } catch {
            exportedContent = "; Failed to export zone file: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
