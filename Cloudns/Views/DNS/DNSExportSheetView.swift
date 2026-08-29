import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - TextDocument

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

// MARK: - ShareSheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - DNSExportSheetView

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
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("; BIND Zone File Export Preview")
                            Text("$ORIGIN example.com.")
                            Text("$TTL 3600")
                            Text("@ IN SOA ns1.cloudflare.com. dns.cloudflare.com. ( 2024010101 10000 2400 604800 3600 )")
                            Text("@ IN NS ns1.cloudflare.com.")
                            Text("@ IN A 192.0.2.1")
                            Text("www IN CNAME example.com.")
                        }
                        .font(.caption.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                    }
                    .redacted(reason: .placeholder)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
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
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            HStack(spacing: 10) {
                                Button {
                                    UIPasteboard.general.string = exportedContent
                                    ToastManager.shared.showCopied("BIND Zone File Copied")
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .foregroundStyle(.white)
                                }
                                
                                Button {
                                    HIGFeedback.impact(.light)
                                    showingShareSheet = true
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                
                                Button {
                                    HIGFeedback.impact(.light)
                                    showingFileExporter = true
                                } label: {
                                    Label("Save", systemImage: "folder")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preview")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                
                                Text(exportedContent)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.primary)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Export Zone File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
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
                    HIGFeedback.success()
                case .failure:
                    HIGFeedback.error()
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .higToast()
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
