import SwiftUI
import UIKit

// MARK: - CodeEditorView
struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String
    var isEditable: Bool = false
    var wrapLines: Bool = true
    var fontSize: CGFloat = 13.0
    var isDarkMode: Bool = true
    
    func makeUIView(context: Context) -> CodeContainerUIView {
        let container = CodeContainerUIView()
        container.update(
            text: text,
            isEditable: isEditable,
            wrapLines: wrapLines,
            fontSize: fontSize,
            isDarkMode: isDarkMode,
            delegate: context.coordinator
        )
        return container
    }
    
    func updateUIView(_ uiView: CodeContainerUIView, context: Context) {
        uiView.update(
            text: text,
            isEditable: isEditable,
            wrapLines: wrapLines,
            fontSize: fontSize,
            isDarkMode: isDarkMode,
            delegate: context.coordinator
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditorView
        
        init(_ parent: CodeEditorView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if parent.text != textView.text {
                parent.text = textView.text
            }
        }
    }
}

// MARK: - CodeContainerUIView (Line Numbers + Highlighting TextView)
final class CodeContainerUIView: UIView {
    private let lineNumbersTextView = UITextView()
    private let codeTextView = UITextView()
    private let separatorView = UIView()
    
    private var offsetObserver: NSKeyValueObservation?
    private var currentText: String = ""
    private var currentFontSize: CGFloat = 13.0
    private var currentWrapLines: Bool = true
    private var currentIsDarkMode: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    deinit {
        offsetObserver?.invalidate()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        
        // 1. Line Numbers Gutter
        lineNumbersTextView.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        lineNumbersTextView.backgroundColor = .clear
        lineNumbersTextView.textColor = UIColor.secondaryLabel.withAlphaComponent(0.6)
        lineNumbersTextView.textAlignment = .right
        lineNumbersTextView.isEditable = false
        lineNumbersTextView.isSelectable = false
        lineNumbersTextView.isScrollEnabled = false
        lineNumbersTextView.showsVerticalScrollIndicator = false
        lineNumbersTextView.showsHorizontalScrollIndicator = false
        lineNumbersTextView.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 32, right: 8)
        lineNumbersTextView.textContainer.lineFragmentPadding = 0
        addSubview(lineNumbersTextView)
        
        // 2. Vertical Divider
        separatorView.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        addSubview(separatorView)
        
        // 3. Code Text View
        codeTextView.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        codeTextView.backgroundColor = .clear
        codeTextView.isSelectable = true
        codeTextView.isScrollEnabled = true
        codeTextView.alwaysBounceVertical = true
        codeTextView.keyboardDismissMode = .interactive
        codeTextView.showsVerticalScrollIndicator = true
        codeTextView.showsHorizontalScrollIndicator = true
        codeTextView.autocapitalizationType = .none
        codeTextView.autocorrectionType = .no
        codeTextView.smartDashesType = .no
        codeTextView.smartQuotesType = .no
        codeTextView.smartInsertDeleteType = .no
        codeTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 32, right: 14)
        codeTextView.textContainer.lineFragmentPadding = 0
        addSubview(codeTextView)
        
        // 4. Frame-perfect Lockstep Scroll Sync via KVO
        offsetObserver = codeTextView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.syncGutterScroll()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let gutterWidth: CGFloat = 46.0
        lineNumbersTextView.frame = CGRect(x: 0, y: 0, width: gutterWidth, height: bounds.height)
        separatorView.frame = CGRect(x: gutterWidth, y: 0, width: 0.5, height: bounds.height)
        codeTextView.frame = CGRect(x: gutterWidth + 0.5, y: 0, width: max(bounds.width - gutterWidth - 0.5, 0), height: bounds.height)
    }
    
    func update(
        text: String,
        isEditable: Bool,
        wrapLines: Bool,
        fontSize: CGFloat,
        isDarkMode: Bool,
        delegate: UITextViewDelegate
    ) {
        codeTextView.delegate = delegate
        codeTextView.isEditable = isEditable
        
        let configChanged = (fontSize != currentFontSize) || (wrapLines != currentWrapLines) || (isDarkMode != currentIsDarkMode)
        let textChanged = (text != currentText)
        
        currentFontSize = fontSize
        currentWrapLines = wrapLines
        currentIsDarkMode = isDarkMode
        
        if configChanged {
            lineNumbersTextView.font = UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular)
            lineNumbersTextView.textColor = isDarkMode ? UIColor(white: 0.5, alpha: 0.6) : UIColor(white: 0.4, alpha: 0.6)
            
            codeTextView.showsHorizontalScrollIndicator = !wrapLines
            if wrapLines {
                codeTextView.textContainer.widthTracksTextView = true
                codeTextView.textContainer.lineBreakMode = .byWordWrapping
            } else {
                codeTextView.textContainer.widthTracksTextView = false
                codeTextView.textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                codeTextView.textContainer.lineBreakMode = .byClipping
            }
        }
        
        if textChanged || configChanged {
            currentText = text
            
            // Apply Syntax Highlighting
            let highlighted = CloudnsCodeHighlighter.highlight(
                code: text,
                fontSize: fontSize,
                isDarkMode: isDarkMode
            )
            
            let selectedRange = codeTextView.selectedRange
            codeTextView.attributedText = highlighted
            if isEditable && selectedRange.location + selectedRange.length <= text.utf16.count {
                codeTextView.selectedRange = selectedRange
            }
            
            // Build Line Numbers String
            let linesCount = max(text.components(separatedBy: "\n").count, 1)
            let lineNumbersStr = (1...linesCount).map { "\($0)" }.joined(separator: "\n")
            lineNumbersTextView.text = lineNumbersStr
            
            syncGutterScroll()
        }
    }
    
    private func syncGutterScroll() {
        lineNumbersTextView.contentOffset = CGPoint(x: 0, y: codeTextView.contentOffset.y)
    }
}
