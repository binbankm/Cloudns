import SwiftUI
import UniformTypeIdentifiers

// MARK: - DNSExportSheetView

struct DNSExportSheetView: View {
    // MARK: - Properties
    let zoneName: String
    let zoneId: String
    let records: [DNSRecord]
    @ObservedObject var viewModel: DNSRecordsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportedContent: String = ""
    @State private var exportedFileURL: URL?
    @State private var isLoading = true
    @State private var showingFileExporter = false
    @State private var showingShareSheet = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Generating BIND Zone File...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header Information Card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundStyle(.blue)
                                    Text("BIND RFC 1035 Zone File")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(records.count) Records")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                                
                                Text("Standard zone file format compatible with Cloudflare, BIND, Route 53, and standard DNS servers.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .background(CloudnsColor.secondaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
                            
                            // Action Buttons Strip
                            HStack(spacing: 10) {
                                Button {
                                    UIPasteboard.general.string = exportedContent
                                    HapticManager.notification(.success)
                                    CloudnsToastManager.shared.showCopied("Zone file copied to clipboard")
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                                }
                                
                                Button {
                                    HapticManager.impact(.light)
                                    showingShareSheet = true
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                                }
                                
                                Button {
                                    HapticManager.impact(.light)
                                    showingFileExporter = true
                                } label: {
                                    Label("Save", systemImage: "folder")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                                }
                            }
                            
                            // Code Preview Box
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preview")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                ScrollView([.horizontal, .vertical]) {
                                    Text(exportedContent)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.primary)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(minHeight: 280)
                                .background(CloudnsColor.tertiaryGroupedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.smMd, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CloudnsRadius.smMd, style: .continuous)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(CloudnsColor.groupedBackground)
            .navigationTitle("Export DNS Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
            .task {
                await loadExportContent()
            }
            .fileExporter(
                isPresented: $showingFileExporter,
                document: TextDocument(url: exportedFileURL),
                contentType: .plainText,
                defaultFilename: "\(zoneName).zone"
            ) { result in
                switch result {
                case .success:
                    CloudnsToastManager.shared.showSuccess("Saved", message: "\(zoneName).zone")
                case .failure(let error):
                    CloudnsToastManager.shared.showError("Save Failed", message: error.localizedDescription)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                } else {
                    ShareSheet(activityItems: [exportedContent])
                }
            }
        }
    }
    
    // MARK: - Actions
    private func loadExportContent() async {
        isLoading = true
        do {
            let url = try await viewModel.exportRecords()
            self.exportedFileURL = url
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                self.exportedContent = text
            } else {
                self.exportedContent = generateFallbackZoneFile()
            }
        } catch {
            self.exportedContent = generateFallbackZoneFile()
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(zoneName).zone")
            try? self.exportedContent.write(to: tempURL, atomically: true, encoding: .utf8)
            self.exportedFileURL = tempURL
        }
        isLoading = false
    }
    
    private func generateFallbackZoneFile() -> String {
        var lines: [String] = []
        lines.append(";;")
        lines.append(";; BIND Zone File for \(zoneName)")
        lines.append(";; Exported by Cloudns on \(DateFormatters.mediumDateTime.string(from: Date()))")
        lines.append(";;")
        lines.append("$ORIGIN \(zoneName).")
        lines.append("$TTL 300")
        lines.append("")
        
        for r in records {
            let name = r.name.hasSuffix(zoneName) ? r.name : "\(r.name).\(zoneName)"
            let ttl = r.ttl == 1 ? "300" : "\(r.ttl)"
            let type = r.type
            let content = r.content ?? ""
            let commentSuffix: String
            if let comment = r.comment, !comment.isEmpty {
                commentSuffix = " ; \(comment)"
            } else {
                commentSuffix = ""
            }
            lines.append("\(name).\t\(ttl)\tIN\t\(type)\t\(content)\(commentSuffix)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - ShareSheet Helper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
