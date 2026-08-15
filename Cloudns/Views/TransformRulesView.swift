import SwiftUI

struct TransformRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel: TransformRulesViewModel
    @State private var showingAddSheet = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: TransformRulesViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                if viewModel.isLoading && viewModel.rules.isEmpty {
                    List {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonRowView()
                        }
                    }
                    .listStyle(.insetGrouped)
                } else if viewModel.rules.isEmpty {
                    EmptyStateView(
                        icon: "arrow.triangle.2.circlepath",
                        title: "No Transform Rules",
                        message: "You haven't created any URL rewrite or header modification rules yet.",
                        actionTitle: "Add Transform Rule",
                        action: { showingAddSheet = true }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    List {
                        ForEach(viewModel.rules) { rule in
                            TransformRuleCardView(rule: rule) {
                                Task {
                                    await viewModel.toggleRule(rule: rule)
                                    ToastManager.shared.showSuccess("Transform Rule Updated", message: "\(rule.description ?? "Rule") status updated")
                                }
                            }
                        }
                        .onDelete(perform: { indexSet in
                            for index in indexSet {
                                let rule = viewModel.rules[index]
                                viewModel.deleteRule(at: IndexSet(integer: index))
                                ToastManager.shared.showSuccess("Transform Rule Deleted", message: rule.description ?? "")
                            }
                        })
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.fetchTransformRules()
                    }
                }
            }
        }
        .navigationTitle("Transform Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTransformRuleView(zoneId: zoneId, viewModel: viewModel)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchTransformRules()
            }
        }
        .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                }
            )
        }
    }
}

struct TransformRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(.body)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            Text(rule.expression)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(6)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(4)
                .lineLimit(2)
            
            if rule.action == "rewrite", let path = rule.action_parameters?.uri?.path?.value {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Rewrite to: \(path)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
