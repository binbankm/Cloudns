import SwiftUI
import UniformTypeIdentifiers

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
