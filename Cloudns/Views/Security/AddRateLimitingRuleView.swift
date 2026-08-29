import SwiftUI

struct AddRateLimitingRuleView: View {
    let zoneId: String
    @ObservedObject var viewModel: RateLimitingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleName = ""
    @State private var pathFilter = ""
    @State private var action = "block"
    
    @State private var period: Int = 10
    @State private var requests: String = "50"
    @State private var timeout: Int = 10
    
    @State private var isSubmitting = false
    
    enum Field { case name, path, requests }
    @FocusState private var focusedField: Field?
    
    let actions = [
        ("Block", "block"),
        ("Managed Challenge", "managed_challenge"),
        ("JS Challenge", "js_challenge"),
        ("Log", "log")
    ]
    
    let periods = [
        (10, "10 seconds"),
        (60, "1 minute"),
        (120, "2 minutes"),
        (300, "5 minutes"),
        (600, "10 minutes"),
        (3600, "1 hour")
    ]
    
    let timeouts = [
        (10, "10 seconds"),
        (60, "1 minute"),
        (600, "10 minutes"),
        (3600, "1 hour"),
        (86400, "1 day")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Details"), footer: Text("Protect your site from DDoS and brute force attacks.")) {
                    TextField("Rule Name (e.g. Protect login)", text: $ruleName)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .name)
                        .onSubmit { focusedField = .path }
                    TextField("Path Filter (optional, e.g. /login)", text: $pathFilter)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .path)
                        .onSubmit { focusedField = .requests }
                }
                
                Section(header: Text("Rate Limit Configuration")) {
                    Picker("Time Window", selection: $period) {
                        ForEach(periods, id: \.0) { val, name in
                            Text(name).tag(val)
                        }
                    }
                    
                    HStack {
                        Text("Requests Per Window")
                        Spacer()
                        TextField("50", text: $requests)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .requests)
                    }
                }
                
                Section(header: Text("Then...")) {
                    Picker("Take Action", selection: $action) {
                        ForEach(actions, id: \.1) { name, val in
                            Text(name).tag(val)
                        }
                    }
                    
                    if action == "block" {
                        Picker("For a duration of", selection: $timeout) {
                            ForEach(timeouts, id: \.0) { val, name in
                                Text(name).tag(val)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Rate Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            await submitRule()
                        }
                    }
                    .disabled(ruleName.isEmpty || requests.isEmpty || Int(requests) == nil || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .overlay(
                Group {
                    if isSubmitting {
                        Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                        ProgressView("Saving...")
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            )
            .toastContainer()
        }
    }
    
    private func submitRule() async {
        guard let requestCount = Int(requests) else { return }
        isSubmitting = true
        
        let ratelimit = RateLimitConfig(
            characteristics: ["ip.src", "cf.colo.id"],
            mitigation_timeout: timeout,
            period: period,
            requests_per_period: requestCount
        )
        
        let expr: String
        let trimmedPath = pathFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPath.isEmpty {
            expr = "http.request.uri.path contains \"\(trimmedPath)\""
        } else {
            expr = "true"
        }
        
        await viewModel.createRule(
            zoneId: zoneId,
            action: action,
            expression: expr,
            description: ruleName,
            enabled: true,
            ratelimit: ratelimit
        )
        
        isSubmitting = false
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}
