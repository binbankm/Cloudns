import SwiftUI

// MARK: - WorkersAIPlaygroundSheetView

struct WorkersAIPlaygroundSheetView: View {
    @ObservedObject var viewModel: WorkersAIViewModel
    let model: AIModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    
    private let samplePrompts = [
        "Explain Cloudflare Workers in simple terms",
        "Write a TypeScript fetch router example",
        "How does edge caching work?",
        "Compare SQL (D1) and Key-Value (KV) storage"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Info Bar
                modelHeaderBar
                
                Divider()
                
                // Chat Message Stream
                chatMessagesArea
                
                Divider()
                
                // Bottom Input Area
                chatInputBar
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(model.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.chatMessages.isEmpty {
                        Button(role: .destructive) {
                            HapticManager.impact(.medium)
                            viewModel.clearChat()
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header Bar
    
    private var modelHeaderBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 28, height: 28)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.shortName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(model.taskName)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Text(model.modelPath)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    // MARK: - Chat Messages Area
    
    private var chatMessagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if viewModel.chatMessages.isEmpty {
                        emptyStateSuggestions
                    } else {
                        ForEach(viewModel.chatMessages) { message in
                            chatBubble(for: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isSendingMessage {
                            typingIndicatorBubble
                                .id("typing_indicator")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.chatMessages.count) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    if let last = viewModel.chatMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isSendingMessage) { sending in
                if sending {
                    withAnimation {
                        proxy.scrollTo("typing_indicator", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State Suggestions
    
    private var emptyStateSuggestions: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(.purple.opacity(0.8))
                    .padding(.top, 24)
                
                Text("Workers AI Edge Playground")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let desc = model.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Suggested prompts:")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                
                ForEach(samplePrompts, id: \.self) { prompt in
                    Button {
                        viewModel.promptInput = prompt
                        isInputFocused = true
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                            Text(prompt)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Message Bubble
    
    @ViewBuilder
    private func chatBubble(for message: AIChatMessageItem) -> some View {
        if message.role == "user" {
            HStack(alignment: .bottom, spacing: 8) {
                Spacer(minLength: 40)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        } else {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(message.isError ? .red : .purple)
                    .frame(width: 26, height: 26)
                    .background((message.isError ? Color.red : Color.purple).opacity(0.12))
                    .clipShape(Circle())
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.content)
                        .font(.body)
                        .foregroundStyle(message.isError ? .red : .primary)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    if !message.isError {
                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = message.content
                                HapticManager.impact(.light)
                                ToastManager.shared.showCopied("Response copied")
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                        }
                        .padding(.leading, 4)
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Typing Indicator
    
    private var typingIndicatorBubble: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(.purple)
                .frame(width: 26, height: 26)
                .background(Color.purple.opacity(0.12))
                .clipShape(Circle())
            
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Inferencing on Cloudflare edge...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Input Bar
    
    private var chatInputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask \(model.shortName)...", text: $viewModel.promptInput, axis: .vertical)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .focused($isInputFocused)
                .disabled(viewModel.isSendingMessage)
                .submitLabel(.send)
                .onSubmit {
                    guard !viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isSendingMessage else { return }
                    isInputFocused = false
                    Task {
                        HapticManager.impact(.light)
                        await viewModel.sendMessage(model: model.modelPath)
                    }
                }
            
            Button {
                isInputFocused = false
                Task {
                    HapticManager.impact(.light)
                    await viewModel.sendMessage(model: model.modelPath)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingMessage
                        ? Color.gray.opacity(0.4)
                        : Color.purple
                    )
            }
            .disabled(viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingMessage)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}
