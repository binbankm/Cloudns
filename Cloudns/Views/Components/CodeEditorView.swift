import SwiftUI
import UIKit

struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String
    var isEditable: Bool = false
    var wrapLines: Bool = true
    var fontSize: CGFloat = 13.0
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.backgroundColor = .clear
        textView.textColor = UIColor.label
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = !wrapLines
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 24, right: 12)
        
        if wrapLines {
            textView.textContainer.widthTracksTextView = true
            textView.textContainer.lineBreakMode = .byWordWrapping
        } else {
            textView.textContainer.widthTracksTextView = false
            textView.textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainer.lineBreakMode = .byClipping
        }
        
        textView.delegate = context.coordinator
        textView.text = text
        
        // Ensure initial scroll position is pinned at the top-left (0, 0)
        DispatchQueue.main.async {
            textView.setContentOffset(.zero, animated: false)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.isEditable != isEditable {
            uiView.isEditable = isEditable
            if !isEditable && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
        
        if uiView.text != text {
            let selectedRange = uiView.selectedRange
            uiView.text = text
            uiView.selectedRange = selectedRange
        }
        
        let shouldTrackWidth = wrapLines
        if uiView.textContainer.widthTracksTextView != shouldTrackWidth {
            uiView.textContainer.widthTracksTextView = shouldTrackWidth
            uiView.showsHorizontalScrollIndicator = !wrapLines
            if shouldTrackWidth {
                let availWidth = max(uiView.bounds.width - uiView.textContainerInset.left - uiView.textContainerInset.right, 0)
                uiView.textContainer.size = CGSize(width: availWidth > 0 ? availWidth : 300, height: CGFloat.greatestFiniteMagnitude)
                uiView.textContainer.lineBreakMode = .byWordWrapping
            } else {
                uiView.textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                uiView.textContainer.lineBreakMode = .byClipping
            }
            uiView.setNeedsLayout()
            uiView.layoutIfNeeded()
        }
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
