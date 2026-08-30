import SwiftUI

// MARK: - WorkersAIView

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
                                .buttonStyle(.plain)
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
        HStack(spacing: 6) {
            Image(systemName: iconForTask(rawName))
                .font(.caption2.weight(.bold))
                .foregroundStyle(.purple)
            
            Text(localizedTaskName(rawName))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption2.monospacedDigit().weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.tertiarySystemFill))
                .clipShape(Capsule())
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func modelRow(_ model: AIModel) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: iconForTask(model.taskName))
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(model.shortName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let vendor = vendorFromModel(model) {
                        Text(vendor)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color(.tertiarySystemFill))
                            .foregroundStyle(.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }
                
                if let desc = model.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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
                    LazyVStack(spacing: 12) {
                        if viewModel.chatMessages.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(.largeTitle, design: .rounded).weight(.medium))
                                    .foregroundStyle(.purple)
                                    .padding(.top, 40)
                                
                                Text(model.shortName)
                                    .font(.headline)
                                
                                if let desc = model.description {
                                    Text(desc)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                }
                            }
                        } else {
                            ForEach(viewModel.chatMessages) { msg in
                                HStack {
                                    if msg.role == "user" {
                                        Spacer()
                                        Text(msg.content)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color.accentColor)
                                            .foregroundStyle(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    } else {
                                        Text(msg.content)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(Color(.secondarySystemBackground))
                                            .foregroundStyle(msg.isError ? .red : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                Divider()
                
                HStack(spacing: 10) {
                    TextField("Ask \(model.shortName)...", text: $viewModel.promptInput)
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
                                .font(.title2)
                        }
                    }
                    .disabled(viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingMessage)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .navigationTitle(model.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
