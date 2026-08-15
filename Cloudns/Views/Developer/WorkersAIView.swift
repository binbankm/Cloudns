import SwiftUI

struct WorkersAIView: View {
    let accountId: String
    @StateObject private var viewModel: WorkersAIViewModel
    @State private var selectedModelForPlayground: AIModel? = nil
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: WorkersAIViewModel(accountId: accountId))
    }
    
    var body: some View {
        contentView
            .navigationTitle("Workers AI")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search AI Models")
            .sheet(item: $selectedModelForPlayground) { model in
                WorkersAIPlaygroundSheetView(viewModel: viewModel, model: model)
            }
            .refreshable {
                await viewModel.fetchModels()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchModels()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading && !viewModel.hasFetchedData {
                List {
                    Section {
                        ForEach(0..<6, id: \.self) { _ in
                            SkeletonRowView()
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchModels() }
                    }
                )
            } else if viewModel.models.isEmpty {
                EmptyStateView(
                    icon: "brain",
                    title: "No Models Found",
                    message: "Unable to retrieve Workers AI model catalog.",
                    actionTitle: "Retry",
                    action: { Task { await viewModel.fetchModels() } }
                )
            } else if viewModel.filteredModels.isEmpty {
                EmptyStateView.search(query: viewModel.searchText) {
                    viewModel.searchText = ""
                }
            } else {
                List {
                    ForEach(viewModel.groupedModels.keys.sorted(), id: \.self) { taskName in
                        if let list = viewModel.groupedModels[taskName], !list.isEmpty {
                            Section(header: Text(taskName)) {
                                ForEach(list) { model in
                                    Button {
                                        selectedModelForPlayground = model
                                    } label: {
                                        HStack(alignment: .center, spacing: 14) {
                                            Image(systemName: "sparkles")
                                                .font(.body)
                                                .foregroundStyle(.purple)
                                                .frame(width: 32, height: 32)
                                                .background(Color.purple.opacity(0.12))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
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
                                                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct WorkersAIPlaygroundSheetView: View {
    @ObservedObject var viewModel: WorkersAIViewModel
    let model: AIModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Model Information")) {
                    HStack {
                        Text("Model Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(model.shortName)
                            .font(.body)
                    }
                    
                    HStack {
                        Text("Task Type")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(model.taskName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.12))
                            .foregroundStyle(.purple)
                            .cornerRadius(4)
                    }
                    
                    if let desc = model.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Inference Playground"), footer: Text("Run serverless AI inference directly on Cloudflare edge GPUs.")) {
                    TextField("Enter prompt or input text...", text: $viewModel.promptInput, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Button {
                        Task {
                            await viewModel.runInference(model: model.id)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isInferenceRunning {
                                ProgressView()
                                    .padding(.trailing, 4)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text("Run Model Inference")
                                .font(.body)
                                .foregroundStyle(.purple)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.promptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isInferenceRunning)
                }
                
                if !viewModel.inferenceOutput.isEmpty {
                    Section(header: HStack {
                        Text("Output Result")
                        Spacer()
                        Button {
                            UIPasteboard.general.string = viewModel.inferenceOutput
                            ToastManager.shared.showCopied("Inference output copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                    }) {
                        Text(viewModel.inferenceOutput)
                            .font(.body.monospacedDigit())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("AI Playground")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .toastContainer()
        }
    }
}
