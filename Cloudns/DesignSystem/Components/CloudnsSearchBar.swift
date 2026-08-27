import SwiftUI

// MARK: - CloudnsSearchBar

/// 符合 Apple HIG 工业标准的内容区原生搜索条组件
/// 不侵入 UINavigationBar 全局高度，彻底杜绝父子页面 Push/Pop 转场时的上下抖动与骨架屏重叠问题。
public struct CloudnsSearchBar: View {
    @Binding var text: String
    var prompt: LocalizedStringKey
    var onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        prompt: LocalizedStringKey = "Search...",
        onCommit: (() -> Void)? = nil
    ) {
        self._text = text
        self.prompt = prompt
        self.onCommit = onCommit
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            TextField(prompt, text: $text)
                .font(.system(size: 16))
                .textFieldStyle(.plain)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    onCommit?()
                }
            
            if !text.isEmpty {
                Button {
                    HapticManager.selection()
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search text")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.smMd, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
    }
}
