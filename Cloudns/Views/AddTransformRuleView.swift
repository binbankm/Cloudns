import SwiftUI

struct AddTransformRuleView: View {
    let zoneId: String
    @ObservedObject var viewModel: TransformRulesViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var ruleName = ""
    @State private var rewritePath = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name (e.g. Rewrite API to v2)", text: $ruleName)
                }
                
                Section(header: Text("Rewrite Action"), footer: Text("All traffic matching this rule will have its URI path rewritten to the specified static path before reaching your origin server.")) {
                    HStack {
                        Text("Static Path")
                        Spacer()
                        TextField("e.g. /api/v2", text: $rewritePath)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("New URL Rewrite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await submitRule()
                        }
                    }
                    .disabled(ruleName.isEmpty || rewritePath.isEmpty || isSubmitting)
                }
            }
            .overlay(
                Group {
                    if isSubmitting {
                        Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                        ProgressView("Saving...")
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                    }
                }
            )
        }
    }
    
    private func submitRule() async {
        isSubmitting = true
        
        await viewModel.createRewriteRule(
            zoneId: zoneId,
            expression: "(http.request.uri.path contains \"/\")", // Default expression for simplicity
            description: ruleName,
            enabled: true,
            rewritePath: rewritePath
        )
        
        isSubmitting = false
        if viewModel.errorMessage == nil {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
