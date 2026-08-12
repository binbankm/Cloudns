import SwiftUI

struct RulesCenterView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: RulesViewModel
    
    init(zoneId: String, zoneName: String) {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: RulesViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 48))
                        .foregroundColor(.teal)
                    Text("Rules & Routing")
                        .font(.title2.bold())
                    Text("Manage page rules and traffic routing for \(zoneName).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }
                
                // Smart Routing Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Argo Smart Routing")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack {
                        Toggle(isOn: Binding(
                            get: { viewModel.argoEnabled },
                            set: { newValue in
                                Task { await viewModel.toggleArgo(isOn: newValue) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Smart Routing")
                                    .font(.body)
                                Text("Route traffic across the fastest paths on the Cloudflare network.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(viewModel.isArgoLoading)
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Page Rules Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Page Rules")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.rules.count) active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isLoading && viewModel.rules.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.rules.isEmpty {
                        EmptyStateView(
                            icon: "list.bullet.rectangle",
                            title: "No Page Rules",
                            message: "No page rules configured."
                        )
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        ForEach(viewModel.rules) { rule in
                            PageRuleCard(rule: rule, onToggle: {
                                Task { await viewModel.toggleRuleStatus(rule: rule) }
                            }, onDelete: {
                                Task { await viewModel.deleteRule(ruleId: rule.id) }
                            })
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Rules & Routing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.rules.isEmpty {
                await viewModel.fetchData()
            }
        }
        .refreshable {
            await viewModel.fetchData()
        }
    }
}

struct PageRuleCard: View {
    let rule: PageRule
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Priority \(rule.priority)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        
                        if rule.status == "disabled" {
                            Text("Disabled")
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    if let urlTarget = rule.targets.first(where: { $0.target == "url" }) {
                        Text(urlTarget.constraint.value)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { rule.status == "active" },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            Divider()
            
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("\(rule.actions.count) actions applied")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Rule", systemImage: "trash")
            }
        }
    }
}
