import SwiftUI

// MARK: - WorkersAIView
// Apple HIG Compliant Cloudflare Workers AI Catalog & Playground

struct WorkersAIView: View {
    let accountId: String
    @StateObject private var viewModel: WorkersAIViewModel
    @State private var selectedModelForPlayground: AIModel?
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: WorkersAIViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredModels.isEmpty {
                ForEach(viewModel.groupedModels.keys.sorted(), id: \.self) { taskName in
                    if let list = viewModel.groupedModels[taskName], !list.isEmpty {
                        Section {
                            ForEach(list) { model in
                                Button {
                                    HIGFeedback.selection()
                                    selectedModelForPlayground = model
                                } label: {
                                    modelRow(model)
                                }
                                .buttonStyle(.higPressable)
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = model.modelPath
                                        ToastManager.shared.showCopied("Model Path Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Model Path", systemImage: "doc.on.doc")
                                    }
                                    
                                    Button {
                                        selectedModelForPlayground = model
                                    } label: {
                                        Label("Open Playground", systemImage: "play.circle")
                                    }
                                }
                            }
                        } header: {
                            categoryHeader(taskName, count: list.count)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search AI Models"
        )
        .navigationTitle("Workers AI")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedModelForPlayground) { model in
            WorkersAIPlaygroundSheetView(viewModel: viewModel, model: model)
                .higToast()
        }
        .refreshable {
            await viewModel.fetchModels()
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.models.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchModels() } }
                        )
                    )
                } else if viewModel.models.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Models Found",
                            systemImage: "brain",
                            description: "Unable to retrieve Workers AI model catalog.",
                            actionTitle: "Retry",
                            action: { Task { await viewModel.fetchModels() } }
                        )
                    )
                } else if viewModel.filteredModels.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchModels()
            }
        }
    }
    
    @ViewBuilder
    private func categoryHeader(_ rawName: String, count: Int) -> some View {
        HStack(spacing: HIGTokens.Spacing.xs) {
            Image(systemName: iconForTask(rawName))
                .font(HIGTypography.caption2.weight(.bold))
                .foregroundStyle(.purple)
            
            Text(localizedTaskName(rawName))
                .font(HIGTypography.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(HIGTypography.caption2.monospacedDigit().weight(.semibold))
                .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                .padding(.vertical, HIGTokens.Spacing.xxs)
                .background(Color(.tertiarySystemFill))
                .clipShape(Capsule())
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func modelRow(_ model: AIModel) -> some View {
        HStack(alignment: .center, spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: iconForTask(model.taskName), color: .purple)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                HStack(spacing: HIGTokens.Spacing.xs + 2) {
                    Text(model.shortName)
                        .font(HIGTypography.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let vendor = vendorFromModel(model) {
                        Text(vendor)
                            .font(HIGTypography.caption2.weight(.semibold))
                            .padding(.horizontal, HIGTokens.Spacing.xs + 1)
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                            .background(Color(.tertiarySystemFill))
                            .foregroundStyle(.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                    }
                }
                
                if let desc = model.description, !desc.isEmpty {
                    Text(desc)
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: HIGTokens.Spacing.sm)
            
            Image(systemName: "chevron.right")
                .font(HIGTypography.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    private func vendorFromModel(_ model: AIModel) -> String? {
        let parts = model.modelPath.split(separator: "/")
        if parts.count >= 2 {
            let v = String(parts[parts.count - 2])
            if v != "@cf" {
                return v.capitalized
            }
        }
        return nil
    }
    
    private func localizedTaskName(_ raw: String) -> LocalizedStringKey {
        let lower = raw.lowercased()
        if lower.contains("speech") || lower.contains("audio") {
            return "Speech Recognition & Audio"
        } else if lower.contains("text-generation") || lower.contains("generation") {
            return "Text Generation (LLM)"
        } else if lower.contains("image") || lower.contains("vision") {
            return "Image & Vision Generation"
        } else if lower.contains("embed") {
            return "Vector Embeddings"
        } else if lower.contains("translation") {
            return "Translation"
        } else if lower.contains("classification") {
            return "Classification"
        }
        return LocalizedStringKey(raw.capitalized)
    }
    
    private func iconForTask(_ task: String) -> String {
        let lower = task.lowercased()
        if lower.contains("speech") || lower.contains("audio") {
            return "waveform"
        } else if lower.contains("text") || lower.contains("generation") {
            return "bubble.left.and.bubble.right.fill"
        } else if lower.contains("image") {
            return "photo.fill"
        } else if lower.contains("embed") {
            return "point.3.connected.trianglepath.dotted"
        } else if lower.contains("translation") {
            return "character.bubble.fill"
        }
        return "sparkles"
    }
}

// MARK: - WorkersAIPlaygroundSheetView (Inlined & Cohesive)

struct WorkersAIPlaygroundSheetView: View {
    @ObservedObject var viewModel: WorkersAIViewModel
    let model: AIModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: HIGTokens.Spacing.md) {
                        if viewModel.chatMessages.isEmpty {
                            VStack(spacing: HIGTokens.Spacing.sm) {
                                Image(systemName: "brain.head.profile")
                                    .font(HIGTypography.largeTitle.weight(.medium))
                                    .foregroundStyle(.purple)
                                    .padding(.top, HIGTokens.Spacing.xxl)
                                
                                Text(model.shortName)
                                    .font(HIGTypography.headline)
                                
                                if let desc = model.description {
                                    Text(desc)
                                        .font(HIGTypography.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, HIGTokens.Spacing.xl)
                                }
                            }
                        } else {
                            ForEach(viewModel.chatMessages) { msg in
                                HStack {
                                    if msg.role == "user" {
                                        Spacer()
                                        Text(msg.content)
                                            .padding(.horizontal, HIGTokens.Spacing.md + 2)
                                            .padding(.vertical, HIGTokens.Spacing.sm + 2)
                                            .background(Color.higAccent)
                                            .foregroundStyle(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                                    } else {
                                        Text(msg.content)
                                            .padding(.horizontal, HIGTokens.Spacing.md + 2)
                                            .padding(.vertical, HIGTokens.Spacing.sm + 2)
                                            .background(Color.higCardBackground)
                                            .foregroundStyle(msg.isError ? HIGColors.error : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, HIGTokens.Spacing.lg)
                            }
                        }
                    }
                    .padding(.vertical, HIGTokens.Spacing.lg)
                }
                
                Divider()
                
                HStack(spacing: HIGTokens.Spacing.sm + 2) {
                    TextField("Ask \(model.shortName)…", text: $viewModel.promptInput)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.send)
                        .onSubmit {
                            Task { await viewModel.sendMessage(model: model.modelPath) }
                        }
                    
                    Button {
                        Task { await viewModel.sendMessage(model: model.modelPath) }
                    } label: {
                        if viewModel.isSendingMessage {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(HIGTypography.title2)
                                .foregroundStyle(viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(.tertiaryLabel) : Color.higAccent)
                        }
                    }
                    .buttonStyle(.higPressable)
                    .disabled(viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingMessage)
                    .higTouchTarget(44)
                }
                .padding(.horizontal, HIGTokens.Spacing.lg)
                .padding(.vertical, HIGTokens.Spacing.sm)
                .background(Color.higGroupBackground)
            }
            .navigationTitle(model.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(HIGTypography.body.weight(.semibold))
                        .foregroundStyle(Color.higAccent)
                        .higTouchTarget()
                }
            }
        }
    }
}
