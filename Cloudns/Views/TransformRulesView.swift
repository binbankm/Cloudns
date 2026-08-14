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
                if viewModel.isLoading && !viewModel.hasFetchedData {
                    Spacer()
                    ProgressView("Loading Transform Rules...")
                    Spacer()
                } else if viewModel.rules.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Transform Rules")
                            .font(.title2.bold())
                        Text("You haven't created any URL rewrite or header modification rules yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.rules) { rule in
                            TransformRuleCardView(rule: rule) {
                                Task {
                                    await viewModel.toggleRule(rule: rule)
                                }
                            }
                        }
                        .onDelete(perform: viewModel.deleteRule)
                    }
                    .listStyle(InsetGroupedListStyle())
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
                    .font(.headline)
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
