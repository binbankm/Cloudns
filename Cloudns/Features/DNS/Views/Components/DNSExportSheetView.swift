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
    
    // Display & Navigation Controls
    @State private var isWrapLines = true
    @State private var showLineNumbers = true
    @State private var searchText = ""
    @State private var previewMode: PreviewMode = .bindFile
    
    private enum PreviewMode: String, CaseIterable, Identifiable {
        case bindFile = "Zone File"
        case structured = "Records"
        var id: String { rawValue }
    }
    
    private var filteredLines: [(index: Int, line: String)] {
        let allLines = exportedContent.components(separatedBy: .newlines)
        let indexed = allLines.enumerated().map { (index: $0.offset + 1, line: $0.element) }
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return indexed
        }
        return indexed.filter { $0.line.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredRecords: [DNSRecord] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return records
        }
        return records.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.localizedCaseInsensitiveContains(searchText) ||
            ($0.content ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.comment ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    VStack(spacing: CloudnsSpacing.md) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Generating BIND Zone File...")
                            .font(CloudnsTypography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: CloudnsSpacing.md) {
                                // Top Anchor for Scroll-To-Top
                                Color.clear
                                    .frame(height: 1)
                                    .id("TOP_ANCHOR")
                                
                                // Header Information Card
                                headerInfoCard
                                
                                // Action Buttons Strip (Copy, Share, Save)
                                actionButtonsStrip
                                
                                // View Mode & Filter Toolbar
                                controlsToolbar(proxy: proxy)
                                
                                // Content Preview
                                if previewMode == .bindFile {
                                    bindFilePreviewView(proxy: proxy)
                                } else {
                                    structuredRecordsPreviewView
                                }
                                
                                // Bottom Anchor for Scroll-To-Bottom
                                Color.clear
                                    .frame(height: 1)
                                    .id("BOTTOM_ANCHOR")
                            }
                            .padding(CloudnsSpacing.md)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            quickScrollFloatingButtons(proxy: proxy)
                        }
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
                    .font(CloudnsTypography.headline)
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
    
    // MARK: - Subviews
    
    private var headerInfoCard: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(CloudnsColor.brand)
                Text("BIND RFC 1035 Zone File")
                    .font(CloudnsTypography.headline)
                Spacer()
                Text("\(records.count) Records")
                    .font(CloudnsTypography.caption.weight(.semibold))
                    .padding(.horizontal, CloudnsSpacing.sm)
                    .padding(.vertical, CloudnsSpacing.xs)
                    .background(CloudnsColor.brandMuted)
                    .foregroundStyle(CloudnsColor.brand)
                    .clipShape(Capsule())
            }
            
            Text("Standard RFC 1035 zone file format compatible with Cloudflare, BIND, Route 53, and standard DNS servers.")
                .font(CloudnsTypography.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(CloudnsSpacing.mdMedium)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous))
    }
    
    private var actionButtonsStrip: some View {
        HStack(spacing: CloudnsSpacing.smMd) {
            Button {
                UIPasteboard.general.string = exportedContent
                HapticManager.notification(.success)
                CloudnsToastManager.shared.showCopied("Zone file copied to clipboard")
            } label: {
                Label("Copy All", systemImage: "doc.on.doc")
                    .font(CloudnsTypography.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CloudnsSpacing.smMd)
                    .background(CloudnsColor.brand)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            }
            
            Button {
                HapticManager.impact(.light)
                showingShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(CloudnsTypography.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CloudnsSpacing.smMd)
                    .background(CloudnsColor.brandMuted)
                    .foregroundStyle(CloudnsColor.brand)
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            }
            
            Button {
                HapticManager.impact(.light)
                showingFileExporter = true
            } label: {
                Label("Save", systemImage: "folder")
                    .font(CloudnsTypography.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, CloudnsSpacing.smMd)
                    .background(CloudnsColor.brandMuted)
                    .foregroundStyle(CloudnsColor.brand)
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            }
        }
    }
    
    private func controlsToolbar(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: CloudnsSpacing.sm) {
            HStack(spacing: CloudnsSpacing.smMd) {
                // Mode Picker (Zone File vs Structured Records)
                Picker("Preview Mode", selection: $previewMode) {
                    ForEach(PreviewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                if previewMode == .bindFile {
                    // Line Wrap Toggle Button
                    Button {
                        withAnimation(CloudnsAnimation.snappy) {
                            isWrapLines.toggle()
                        }
                    } label: {
                        HStack(spacing: CloudnsSpacing.xs) {
                            Image(systemName: isWrapLines ? "text.word.spacing" : "arrow.left.and.right.text.vertical")
                            Text(isWrapLines ? "Wrap On" : "No Wrap")
                                .font(CloudnsTypography.caption.weight(.medium))
                        }
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xs)
                        .background(isWrapLines ? CloudnsColor.brandMuted : CloudnsColor.chipBackground)
                        .foregroundStyle(isWrapLines ? CloudnsColor.brand : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    // Line Numbers Toggle Button
                    Button {
                        withAnimation(CloudnsAnimation.snappy) {
                            showLineNumbers.toggle()
                        }
                    } label: {
                        Image(systemName: "list.number")
                            .font(CloudnsTypography.caption.weight(.medium))
                            .padding(.horizontal, CloudnsSpacing.sm)
                            .padding(.vertical, CloudnsSpacing.xs)
                            .background(showLineNumbers ? CloudnsColor.brandMuted : CloudnsColor.chipBackground)
                            .foregroundStyle(showLineNumbers ? CloudnsColor.brand : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Search Filter inside preview
            HStack(spacing: CloudnsSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(CloudnsTypography.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Filter records or lines...", text: $searchText)
                    .font(CloudnsTypography.subheadline)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(CloudnsTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, CloudnsSpacing.smMd)
            .padding(.vertical, CloudnsSpacing.xs)
            .background(CloudnsColor.secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm, style: .continuous))
        }
    }
    
    private func bindFilePreviewView(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack {
                Text("\(zoneName).zone")
                    .font(CloudnsTypography.codeSmall.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(filteredLines.count) lines")
                    .font(CloudnsTypography.codeSmall)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, CloudnsSpacing.mdMedium)
            .padding(.vertical, CloudnsSpacing.xs)
            .background(CloudnsColor.primaryFill.opacity(0.3))
            
            Divider()
            
            // Lines Display (With Wrap or Horizontal Scroll based on toggle)
            if isWrapLines {
                // Adaptive Word-Wrap Mode: No horizontal scrolling needed!
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(filteredLines, id: \.index) { item in
                        HStack(alignment: .top, spacing: CloudnsSpacing.sm) {
                            if showLineNumbers {
                                Text("\(item.index)")
                                    .font(CloudnsTypography.codeSmall)
                                    .foregroundStyle(.secondary.opacity(0.6))
                                    .frame(width: 28, alignment: .trailing)
                            }
                            
                            highlightedBindLine(item.line)
                                .font(CloudnsTypography.code)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(CloudnsSpacing.mdMedium)
            } else {
                // Horizontal Scroll Mode: for traditional full-width view
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(filteredLines, id: \.index) { item in
                            HStack(alignment: .top, spacing: CloudnsSpacing.sm) {
                                if showLineNumbers {
                                    Text("\(item.index)")
                                        .font(CloudnsTypography.codeSmall)
                                        .foregroundStyle(.secondary.opacity(0.6))
                                        .frame(width: 28, alignment: .trailing)
                                }
                                
                                highlightedBindLine(item.line)
                                    .font(CloudnsTypography.code)
                            }
                        }
                    }
                    .padding(CloudnsSpacing.mdMedium)
                }
            }
        }
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous)
                .stroke(CloudnsColor.separator, lineWidth: 0.5)
        )
    }
    
    private var structuredRecordsPreviewView: some View {
        VStack(spacing: CloudnsSpacing.sm) {
            ForEach(filteredRecords) { record in
                HStack(spacing: CloudnsSpacing.mdSmall) {
                    // Type Badge
                    Text(record.type)
                        .font(CloudnsTypography.codeSmall.weight(.bold))
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xxs)
                        .background(typeBadgeColor(record.type).opacity(0.14))
                        .foregroundStyle(typeBadgeColor(record.type))
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                        Text(record.name)
                            .font(CloudnsTypography.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Text(record.content ?? "")
                            .font(CloudnsTypography.code)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: CloudnsSpacing.xxs) {
                        Text(record.ttl == 1 ? "Auto" : "\(record.ttl)s")
                            .font(CloudnsTypography.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        
                        if record.proxied == true {
                            Image(systemName: "cloud.fill")
                                .font(CloudnsTypography.caption)
                                .foregroundStyle(CloudnsColor.proxied)
                        }
                    }
                }
                .padding(CloudnsSpacing.mdMedium)
                .background(CloudnsColor.secondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
            }
        }
    }
    
    private func quickScrollFloatingButtons(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: CloudnsSpacing.xs) {
            Button {
                withAnimation(CloudnsAnimation.snappy) {
                    proxy.scrollTo("TOP_ANCHOR", anchor: .top)
                }
            } label: {
                Image(systemName: "arrow.up")
                    .font(CloudnsTypography.subheadline.weight(.semibold))
                    .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                    .background(CloudnsColor.secondaryGroupedBackground)
                    .foregroundStyle(.primary)
                    .clipShape(Circle())
                    .cloudnsShadow(.card)
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation(CloudnsAnimation.snappy) {
                    proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom)
                }
            } label: {
                Image(systemName: "arrow.down")
                    .font(CloudnsTypography.subheadline.weight(.semibold))
                    .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                    .background(CloudnsColor.secondaryGroupedBackground)
                    .foregroundStyle(.primary)
                    .clipShape(Circle())
                    .cloudnsShadow(.card)
            }
            .buttonStyle(.plain)
        }
        .padding(CloudnsSpacing.md)
    }
    
    // MARK: - Helpers & Syntax Highlighting
    
    @ViewBuilder
    private func highlightedBindLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix(";;") || trimmed.hasPrefix(";") {
            Text(line)
                .foregroundStyle(.secondary.opacity(0.7))
        } else if trimmed.hasPrefix("$ORIGIN") || trimmed.hasPrefix("$TTL") {
            Text(line)
                .foregroundStyle(CloudnsColor.brand)
        } else {
            let parts = line.components(separatedBy: "\t")
            if parts.count >= 5 {
                HStack(spacing: CloudnsSpacing.xs) {
                    Text(parts[0])
                        .foregroundStyle(.primary)
                    Text(parts[1])
                        .foregroundStyle(CloudnsColor.ai)
                    Text(parts[2])
                        .foregroundStyle(.secondary)
                    Text(parts[3])
                        .foregroundStyle(typeBadgeColor(parts[3]))
                        .fontWeight(.semibold)
                    Text(parts[4])
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(line)
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private func typeBadgeColor(_ type: String) -> Color {
        switch type.uppercased() {
        case "A", "AAAA":
            return .blue
        case "CNAME":
            return .orange
        case "TXT":
            return .green
        case "MX":
            return .purple
        case "NS":
            return .teal
        default:
            return .gray
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
