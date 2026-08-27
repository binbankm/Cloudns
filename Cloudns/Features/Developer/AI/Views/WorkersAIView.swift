import SwiftUI

struct WorkersAIView: View {
    // MARK: - Properties
    let accountId: String
    @StateObject private var viewModel: WorkersAIViewModel
    @State private var selectedModelForPlayground: AIModel?
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: WorkersAIViewModel(accountId: accountId))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search AI Models"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(CloudnsColor.groupedBackground)
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(AIModel.placeholders) { placeholder in
                            modelRow(placeholder)
                        }
                    }
                    .skeletonLoading(true)
                } else if !viewModel.filteredModels.isEmpty {
                    ForEach(viewModel.groupedModels.keys.sorted(), id: \.self) { taskName in
                        if let list = viewModel.groupedModels[taskName], !list.isEmpty {
                            Section(header: Text(taskName)) {
                                ForEach(list) { model in
                                    Button {
                                        HapticManager.impact(.light)
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
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
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
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchModels() } }
                        )
                    )
                } else if viewModel.models.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "brain",
                            title: "No Models Found",
                            message: "Unable to retrieve Workers AI model catalog.",
                            actionTitle: "Retry",
                            action: { Task { await viewModel.fetchModels() } }
                        )
                    )
                } else if viewModel.filteredModels.isEmpty && !viewModel.searchText.isEmpty {
                    CloudnsStateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
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
    // MARK: - Private Views
    private func modelRow(_ model: AIModel) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(model.shortName)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                if let desc = model.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Text(model.id)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color(.tertiaryLabel))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
    }
}
