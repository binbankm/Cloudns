import SwiftUI

struct EmailRoutingView: View {
    let zoneId: String
    
    @StateObject private var viewModel: EmailRoutingViewModel
    @State private var showingAddSheet = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: EmailRoutingViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading && !viewModel.hasFetchedData {
                List {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task {
                            await viewModel.fetchData()
                        }
                    }
                )
            } else {
                List {
                    Section(header: Text("Status")) {
                        HStack {
                            Text("Email Routing")
                            Spacer()
                            if let settings = viewModel.settings {
                                if settings.isEnabled {
                                    Text("Enabled")
                                        .foregroundStyle(.green)
                                } else {
                                    Text("Disabled")
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Unknown")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Section(
                        header: HStack {
                            Text("Routing Rules")
                            Spacer()
                            Button(action: { showingAddSheet = true }) {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("添加邮件路由规则")
                        }
                    ) {
                        if viewModel.rules.isEmpty {
                            EmptyStateView(
                                icon: "envelope.badge.shield.half.filled",
                                title: "No Email Rules",
                                message: "Create custom routing rules to forward incoming emails to external addresses.",
                                actionTitle: "Add Rule",
                                action: { showingAddSheet = true }
                            )
                        } else {
                            ForEach(viewModel.rules) { rule in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        if let match = rule.matchAddress {
                                            Text(match)
                                                .font(.body)
                                        } else if rule.isCatchAll {
                                            Text("Catch-all")
                                                .font(.body)
                                        } else {
                                            Text(rule.name ?? "Rule")
                                                .font(.body)
                                        }
                                        Spacer()
                                        if rule.isEnabled {
                                            Text("Active")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                        } else {
                                            Text("Inactive")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    HStack {
                                        Image(systemName: "arrow.turn.down.right")
                                            .foregroundStyle(.gray)
                                        Text(rule.actionSummary)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: { indexSet in
                                for index in indexSet {
                                    let rule = viewModel.rules[index]
                                    viewModel.deleteRule(at: IndexSet(integer: index))
                                    ToastManager.shared.showSuccess("Email Rule Deleted", message: rule.name ?? "")
                                }
                            })
                        }
                    }
                    
                    Section(header: Text("Destination Addresses")) {
                        if viewModel.destinations.isEmpty {
                            Text("No destination addresses configured.")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(viewModel.destinations) { dest in
                                HStack {
                                    Text(dest.email)
                                    Spacer()
                                    if dest.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Text("Unverified")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Email Routing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSheet) {
            AddEmailRuleView(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchData()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        })
    }
}
