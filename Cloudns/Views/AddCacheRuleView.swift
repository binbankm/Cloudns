import SwiftUI

struct AddCacheRuleView: View {
    let zoneId: String
    @ObservedObject var viewModel: CacheRulesViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var ruleName = ""
    @State private var cacheEligibility = "eligible"
    
    @State private var edgeTtlMode = "respect_origin"
    @State private var edgeTtlValue = "3600"
    
    @State private var browserTtlMode = "respect_origin"
    @State private var browserTtlValue = "14400"
    
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name (e.g. Cache static assets)", text: $ruleName)
                }
                
                Section(header: Text("Cache Eligibility")) {
                    Picker("Eligibility", selection: $cacheEligibility) {
                        Text("Eligible for cache").tag("eligible")
                        Text("Bypass cache").tag("bypass")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if cacheEligibility == "eligible" {
                    Section(header: Text("Edge TTL"), footer: Text("How long resources are cached on Cloudflare's edge network.")) {
                        Picker("Edge TTL Mode", selection: $edgeTtlMode) {
                            Text("Respect Origin").tag("respect_origin")
                            Text("Override Origin").tag("override_origin")
                            Text("Bypass by Default").tag("bypass_by_default")
                        }
                        
                        if edgeTtlMode == "override_origin" {
                            HStack {
                                Text("Seconds")
                                Spacer()
                                TextField("e.g. 3600", text: $edgeTtlValue)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }
                    
                    Section(header: Text("Browser TTL"), footer: Text("How long resources are cached in visitor browsers.")) {
                        Picker("Browser TTL Mode", selection: $browserTtlMode) {
                            Text("Respect Origin").tag("respect_origin")
                            Text("Override Origin").tag("override_origin")
                            Text("Bypass by Default").tag("bypass_by_default")
                        }
                        
                        if browserTtlMode == "override_origin" {
                            HStack {
                                Text("Seconds")
                                Spacer()
                                TextField("e.g. 14400", text: $browserTtlValue)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Cache Rule")
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
                    .disabled(ruleName.isEmpty || isSubmitting)
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
        
        var params = ActionParameters()
        params.cache = (cacheEligibility == "eligible")
        
        if params.cache == true {
            var edgeTtl = CacheEdgeTTL(mode: edgeTtlMode, default_ttl: nil)
            if edgeTtlMode == "override_origin", let val = Int(edgeTtlValue) {
                edgeTtl.default_ttl = val
            }
            params.edge_ttl = edgeTtl
            
            var browserTtl = CacheBrowserTTL(mode: browserTtlMode, default_ttl: nil)
            if browserTtlMode == "override_origin", let val = Int(browserTtlValue) {
                browserTtl.default_ttl = val
            }
            params.browser_ttl = browserTtl
        }
        
        await viewModel.createRule(
            zoneId: zoneId,
            expression: "(http.request.uri.path contains \"/\")", // Default to all paths for simplified creation
            description: ruleName,
            enabled: true,
            actionParameters: params
        )
        
        isSubmitting = false
        if viewModel.errorMessage == nil {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
