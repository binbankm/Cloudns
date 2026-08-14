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
            
            if viewModel.isLoading && viewModel.settings == nil {
                ProgressView("Loading Email Routing...")
            } else {
                List {
                    Section(header: Text("Status")) {
                        HStack {
                            Text("Email Routing")
                            Spacer()
                            if let settings = viewModel.settings {
                                if settings.isEnabled {
                                    Text("Enabled")
                                        .foregroundColor(.green)
                                } else {
                                    Text("Disabled")
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Unknown")
                                    .foregroundColor(.secondary)
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
                        }
                    ) {
                        if viewModel.rules.isEmpty {
                            Text("No routing rules configured.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.rules) { rule in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        if let match = rule.matchAddress {
                                            Text(match)
                                                .font(.headline)
                                        } else if rule.isCatchAll {
                                            Text("Catch-all")
                                                .font(.headline)
                                        } else {
                                            Text(rule.name ?? "Rule")
                                                .font(.headline)
                                        }
                                        Spacer()
                                        if rule.isEnabled {
                                            Text("Active")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        } else {
                                            Text("Inactive")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    HStack {
                                        Image(systemName: "arrow.turn.down.right")
                                            .foregroundColor(.gray)
                                        Text(rule.actionSummary)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: viewModel.deleteRule)
                        }
                    }
                    
                    Section(header: Text("Destination Addresses")) {
                        if viewModel.destinations.isEmpty {
                            Text("No destination addresses.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.destinations) { dest in
                                HStack {
                                    Text(dest.email)
                                    Spacer()
                                    if dest.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Text("Unverified")
                                            .font(.caption)
                                            .foregroundColor(.orange)
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
