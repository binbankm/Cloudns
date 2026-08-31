import SwiftUI
import UIKit

// MARK: - CloudnsCodeHighlighter
/// High-performance, zero-dependency native syntax highlighter specifically tuned for Cloudflare Workers (JS/TS/JSON/SQL).
enum CloudnsCodeHighlighter {
    
    // Cloudflare Edge APIs & Globals
    private static let cloudflareGlobals: Set<String> = [
        "HTMLRewriter", "caches", "WebSocketPair", "Response", "Request", "Headers", "fetch",
        "env", "ctx", "waitUntil", "passThroughOnException", "crypto", "URL", "URLPattern",
        "URLSearchParams", "ReadableStream", "WritableStream", "TransformStream", "TextEncoder",
        "TextDecoder", "console", "D1Database", "KVNamespace", "R2Bucket", "DurableObjectNamespace",
        "Fetcher", "ExecutionContext", "ScheduledController", "MessageBatch", "ArrayBuffer",
        "Uint8Array", "Uint16Array", "Uint32Array", "Int8Array", "Int16Array", "Int32Array", "Promise"
    ]
    
    // Core JS/TS Keywords
    private static let keywords: Set<String> = [
        "import", "export", "default", "async", "await", "function", "return", "const",
        "let", "var", "if", "else", "switch", "case", "break", "continue", "try", "catch",
        "finally", "throw", "new", "typeof", "instanceof", "from", "as", "class", "extends",
        "constructor", "this", "super", "interface", "type", "enum", "public", "private",
        "protected", "readonly", "static", "get", "set", "for", "while", "do", "in", "of",
        "yield", "void", "delete", "with", "debugger"
    ]
    
    // Literals & Constants
    private static let literals: Set<String> = [
        "true", "false", "null", "undefined", "NaN", "Infinity"
    ]
    
    /// Highlights the raw code into an NSAttributedString with adaptive colors for light/dark mode.
    static func highlight(code: String, fontSize: CGFloat = 13.0, isDarkMode: Bool = true) -> NSAttributedString {
        guard !code.isEmpty else { return NSAttributedString(string: "") }
        
        let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let boldFont = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .semibold)
        
        // Color Palette (VS Code Dark+ & Light Theme inspired)
        let defaultColor = isDarkMode ? UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1.0) : UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        let keywordColor = isDarkMode ? UIColor(red: 0.77, green: 0.52, blue: 0.75, alpha: 1.0) : UIColor(red: 0.65, green: 0.15, blue: 0.65, alpha: 1.0) // Purple
        let cfGlobalColor = isDarkMode ? UIColor(red: 0.86, green: 0.62, blue: 0.35, alpha: 1.0) : UIColor(red: 0.85, green: 0.45, blue: 0.10, alpha: 1.0) // Warm Gold/Orange
        let stringColor = isDarkMode ? UIColor(red: 0.42, green: 0.75, blue: 0.55, alpha: 1.0) : UIColor(red: 0.18, green: 0.55, blue: 0.28, alpha: 1.0) // Emerald Green
        let commentColor = isDarkMode ? UIColor(red: 0.45, green: 0.52, blue: 0.45, alpha: 1.0) : UIColor(red: 0.48, green: 0.55, blue: 0.48, alpha: 1.0) // Muted Gray-Green
        let numberColor = isDarkMode ? UIColor(red: 0.38, green: 0.72, blue: 0.88, alpha: 1.0) : UIColor(red: 0.10, green: 0.45, blue: 0.75, alpha: 1.0) // Cyan/Blue
        let propertyColor = isDarkMode ? UIColor(red: 0.61, green: 0.86, blue: 0.99, alpha: 1.0) : UIColor(red: 0.05, green: 0.35, blue: 0.65, alpha: 1.0) // Light Blue
        
        let attributed = NSMutableAttributedString(string: code, attributes: [
            .font: font,
            .foregroundColor: defaultColor
        ])
        
        let nsString = code as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        // 1. Strings: '…', "...", `…`
        let stringPattern = #"\"([^\"\\]|\\.)*\"|'([^'\\]|\\.)*'|`([^`\\]|\\.)*`"#
        if let regex = try? NSRegularExpression(pattern: stringPattern, options: []) {
            regex.enumerateMatches(in: code, options: [], range: fullRange) { match, _, _ in
                if let range = match?.range {
                    attributed.addAttribute(.foregroundColor, value: stringColor, range: range)
                }
            }
        }
        
        // 2. Numbers
        let numberPattern = #"\b\d+(\.\d+)?\b"#
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            regex.enumerateMatches(in: code, options: [], range: fullRange) { match, _, _ in
                if let range = match?.range {
                    attributed.addAttribute(.foregroundColor, value: numberColor, range: range)
                }
            }
        }
        
        // 3. Word identifiers: keywords, CF globals, literals, properties
        let wordPattern = #"\b[A-Za-z_$][A-Za-z0-9_$]*\b"#
        if let regex = try? NSRegularExpression(pattern: wordPattern, options: []) {
            regex.enumerateMatches(in: code, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                let word = nsString.substring(with: range)
                
                if keywords.contains(word) {
                    attributed.addAttributes([
                        .foregroundColor: keywordColor,
                        .font: boldFont
                    ], range: range)
                } else if cloudflareGlobals.contains(word) {
                    attributed.addAttributes([
                        .foregroundColor: cfGlobalColor,
                        .font: boldFont
                    ], range: range)
                } else if literals.contains(word) {
                    attributed.addAttribute(.foregroundColor, value: numberColor, range: range)
                }
            }
        }
        
        // 4. Dot properties (e.g. env.MY_KV, caches.default, request.cf.colo)
        let dotPropPattern = #"\.([A-Za-z_$][A-Za-z0-9_$]*)"#
        if let regex = try? NSRegularExpression(pattern: dotPropPattern, options: []) {
            regex.enumerateMatches(in: code, options: [], range: fullRange) { match, _, _ in
                if let match = match, match.numberOfRanges > 1 {
                    let propRange = match.range(at: 1)
                    let propWord = nsString.substring(with: propRange)
                    if !keywords.contains(propWord) {
                        attributed.addAttribute(.foregroundColor, value: propertyColor, range: propRange)
                    }
                }
            }
        }
        
        // 5. Comments (Single-line // and Multi-line /* */) — must run last to override strings/words
        let commentPattern = #"\/\/[^\n]*|\/\*[\s\S]*?\*\/"#
        if let regex = try? NSRegularExpression(pattern: commentPattern, options: []) {
            regex.enumerateMatches(in: code, options: [], range: fullRange) { match, _, _ in
                if let range = match?.range {
                    attributed.addAttributes([
                        .foregroundColor: commentColor,
                        .font: font
                    ], range: range)
                }
            }
        }
        
        return attributed
    }
}
