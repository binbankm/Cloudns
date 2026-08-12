import SwiftUI

struct IPAccessRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = IPAccessRulesViewModel()
    @State private var showingAddRule = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                }
                
                if viewModel.isLoading && !viewModel.hasFetchedData {
                    Spacer()
                    ProgressView("Loading rules...")
                    Spacer()
                } else if viewModel.rules.isEmpty && viewModel.hasFetchedData {
                    Spacer()
                    EmptyStateView(
                        icon: "network.badge.shield.half.filled",
                        title: "No IP Access Rules",
                        message: "You haven't created any IP access rules yet. Add a rule to block or challenge specific IPs or countries."
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.rules) { rule in
                            IPAccessRuleRow(rule: rule)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
        }
        .navigationTitle("IP Access Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddRule = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRules(zoneId: zoneId)
            }
        }
        .sheet(isPresented: $showingAddRule) {
            AddIPAccessRuleView(zoneId: zoneId, viewModel: viewModel, isPresented: $showingAddRule)
        }
    }
}

struct IPAccessRuleRow: View {
    let rule: IPAccessRule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.configuration.value)
                    .font(.system(.headline, design: .monospaced))
                
                Spacer()
                
                Text(rule.mode.uppercased())
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForMode(rule.mode).opacity(0.1))
                    .foregroundColor(colorForMode(rule.mode))
                    .cornerRadius(6)
            }
            
            HStack {
                Text(rule.configuration.target.uppercased().replacingOccurrences(of: "_", with: " "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let notes = rule.notes, !notes.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForMode(_ mode: String) -> Color {
        switch mode {
        case "block": return .red
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "whitelist": return .green
        default: return .blue
        }
    }
}

struct AddIPAccessRuleView: View {
    let zoneId: String
    @ObservedObject var viewModel: IPAccessRulesViewModel
    @Binding var isPresented: Bool
    
    @State private var target = "ip"
    @State private var value = ""
    @State private var mode = "block"
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Target")) {
                    Picker("Target Type", selection: $target) {
                        Text("IP Address").tag("ip")
                        Text("IP Range").tag("ip_range")
                        Text("Country").tag("country")
                        Text("ASN").tag("asn")
                    }
                    
                    TextField(target == "country" ? "e.g. US, CN, GB" : (target == "asn" ? "e.g. AS12345" : "e.g. 192.168.1.1"), text: $value)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Action")) {
                    Picker("Action", selection: $mode) {
                        Text("Block").tag("block")
                        Text("Managed Challenge").tag("managed_challenge")
                        Text("JS Challenge").tag("js_challenge")
                        Text("Legacy CAPTCHA").tag("challenge")
                        Text("Allow").tag("whitelist")
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Reason for this rule", text: $notes)
                }
            }
            .navigationTitle("Add Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let success = await viewModel.createRule(
                                zoneId: zoneId,
                                mode: mode,
                                target: target,
                                value: value,
                                notes: notes
                            )
                            if success {
                                isPresented = false
                            }
                        }
                    }
                    .disabled(value.isEmpty || viewModel.isCreating)
                }
            }
        }
    }
}
