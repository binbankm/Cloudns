import SwiftUI

// MARK: - WorkersAIPlaygroundSheetView

struct WorkersAIPlaygroundSheetView: View {
    // MARK: - Properties
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
    
    // MARK: - Body
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
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
    
    // MARK: - Private Views
    private var modelHeaderBar: some View {
        HStack(spacing: CloudnsSpacing.smMd) {
            Image(systemName: "sparkles")
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: CloudnsSize.avatarSmall, height: CloudnsSize.avatarSmall)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                HStack(spacing: CloudnsSpacing.sm) {
                    Text(model.shortName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(model.taskName)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, CloudnsSpacing.xs)
                        .padding(.vertical, CloudnsSpacing.xxs)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
                }
                
                Text(model.modelPath)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
        }
        .padding(.horizontal, CloudnsSpacing.md)
        .padding(.vertical, CloudnsSpacing.smMd)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    // MARK: - Chat Messages Area
    
    private var chatMessagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: CloudnsSpacing.mdMedium) {
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
                .padding(.horizontal, CloudnsSpacing.md)
                .padding(.vertical, CloudnsSpacing.md)
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
        VStack(spacing: CloudnsSpacing.md) {
            VStack(spacing: CloudnsSpacing.sm) {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundStyle(.purple.opacity(0.8))
                    .padding(.top, CloudnsSpacing.lg)
                
                Text("Workers AI Edge Playground")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let desc = model.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CloudnsSpacing.mdLarge)
                }
            }
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
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
                        .padding(.horizontal, CloudnsSpacing.mdMedium)
                        .padding(.vertical, CloudnsSpacing.smMd)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.mdLg))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, CloudnsSpacing.sm)
        }
    }
    
    // MARK: - Message Bubble
    
    @ViewBuilder
    private func chatBubble(for message: AIChatMessageItem) -> some View {
        if message.role == "user" {
            HStack(alignment: .bottom, spacing: CloudnsSpacing.sm) {
                Spacer(minLength: 40)
                
                VStack(alignment: .trailing, spacing: CloudnsSpacing.xs) {
                    Text(message.content)
                        .font(.body)
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .padding(.horizontal, CloudnsSpacing.mdMedium)
                        .padding(.vertical, CloudnsSpacing.smMd)
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous))
                }
            }
        } else {
            HStack(alignment: .top, spacing: CloudnsSpacing.smMd) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(message.isError ? .red : .purple)
                    .frame(width: CloudnsSize.iconLarge, height: CloudnsSize.iconLarge)
                    .background((message.isError ? Color.red : Color.purple).opacity(0.12))
                    .clipShape(Circle())
                    .padding(.top, CloudnsSpacing.xs)
                
                VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                    Text(message.content)
                        .font(.body)
                        .foregroundStyle(message.isError ? .red : .primary)
                        .textSelection(.enabled)
                        .padding(.horizontal, CloudnsSpacing.mdMedium)
                        .padding(.vertical, CloudnsSpacing.smMd)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous))
                    
                    if !message.isError {
                        HStack(spacing: CloudnsSpacing.mdSmall) {
                            Button {
                                UIPasteboard.general.string = message.content
                                HapticManager.impact(.light)
                                CloudnsToastManager.shared.showCopied("Response copied")
                            } label: {
                                HStack(spacing: CloudnsSpacing.xs) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                        }
                        .padding(.leading, CloudnsSpacing.xs)
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Typing Indicator
    
    private var typingIndicatorBubble: some View {
        HStack(alignment: .center, spacing: CloudnsSpacing.smMd) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(.purple)
                .frame(width: CloudnsSize.iconLarge, height: CloudnsSize.iconLarge)
                .background(Color.purple.opacity(0.12))
                .clipShape(Circle())
            
            HStack(spacing: CloudnsSpacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Inferencing on Cloudflare edge...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, CloudnsSpacing.mdSmall)
            .padding(.vertical, CloudnsSpacing.sm)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg, style: .continuous))
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Input Bar
    
    private var chatInputBar: some View {
        HStack(alignment: .bottom, spacing: CloudnsSpacing.smMd) {
            TextField("Ask \(model.shortName)...", text: $viewModel.promptInput, axis: .vertical)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(1...5)
                .padding(.horizontal, CloudnsSpacing.mdSmall)
                .padding(.vertical, CloudnsSpacing.sm)
                .background(CloudnsColor.tertiaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xl))
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
                    .font(.title)
                    .foregroundStyle(
                        viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingMessage
                        ? Color.gray.opacity(0.4)
                        : Color.purple
                    )
            }
            .disabled(viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingMessage)
        }
        .padding(.horizontal, CloudnsSpacing.mdMedium)
        .padding(.vertical, CloudnsSpacing.smMd)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}
