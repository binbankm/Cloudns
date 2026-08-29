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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(AIModel.placeholders) { placeholder in
                        modelRow(placeholder)
                    }
                }
                .redacted(reason: .placeholder)
            } else if !viewModel.filteredModels.isEmpty {
                ForEach(viewModel.groupedModels.keys.sorted(), id: \.self) { taskName in
                    if let list = viewModel.groupedModels[taskName], !list.isEmpty {
                        Section(header: Text(taskName)) {
                            ForEach(list) { model in
                                Button {
                                    HIGFeedback.selection()
                                    selectedModelForPlayground = model
                                } label: {
                                    modelRow(model)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search AI Models"
        )
        .navigationTitle("Workers AI")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedModelForPlayground) { model in
            WorkersAIPlaygroundSheetView(viewModel: viewModel, model: model)
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
    private func modelRow(_ model: AIModel) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(model.shortName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let desc = model.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 3)
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
                                    .font(.system(size: 40))
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
