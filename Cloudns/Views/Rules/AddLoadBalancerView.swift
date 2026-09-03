import SwiftUI

// MARK: - AddLoadBalancerView
// Apple HIG Compliant Cloudflare Load Balancer Wizard

struct AddLoadBalancerView: View {
    let zoneId: String
    @ObservedObject var viewModel: LoadBalancerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var enabled: Bool = true
    @State private var proxied: Bool = true
    @State private var ttl: String = "30"
    @State private var steeringPolicy: String = "off"
    @State private var sessionAffinity: String = "none"
    @State private var selectedPools: Set<String> = []
    @State private var fallbackPool: String = ""
    
    @State private var isSubmitting: Bool = false
    
    let steeringOptions = [
        ("Off", "off"),
        ("Geo", "geo"),
        ("Random", "random"),
        ("Dynamic Latency", "dynamic_latency"),
        ("Proximity", "proximity")
    ]
    
    let affinityOptions = [
        ("None", "none"),
        ("Cookie", "cookie"),
        ("IP", "ip_fallback")
    ]
    
    var isValid: Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if selectedPools.isEmpty { return false }
        if fallbackPool.isEmpty { return false }
        if !proxied && Int(ttl) == nil { return false }
        return true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.purple)
                        Text("Cloudflare Load Balancing is a paid add-on service. Make sure it is active on your Cloudflare account.")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                }
                
                Section(header: Text("Basic Details"), footer: Text(proxied ? "When proxied, DNS TTL is managed by Cloudflare." : "TTL applies to DNS-only mode.")) {
                    TextField("Hostname (e.g., lb.example.com)", text: $name)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                    
                    Toggle("Enabled", isOn: $enabled)
                    Toggle("Proxied through Cloudflare", isOn: $proxied)
                    
                    if !proxied {
                        HStack {
                            Text("TTL (seconds)")
                                .font(HIGTypography.body)
                            Spacer()
                            TextField("30", text: $ttl)
                                .font(HIGTypography.body.monospacedDigit())
                                .keyboardType(.numberPad)
                                .autocorrectionDisabled()
                                .multilineTextAlignment(.trailing)
                                .submitLabel(.done)
                                .frame(width: 80)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                Section(header: Text("Traffic Steering")) {
                    Picker("Steering Policy", selection: $steeringPolicy) {
                        ForEach(steeringOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    
                    Picker("Session Affinity", selection: $sessionAffinity) {
                        ForEach(affinityOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }
                
                Section(header: Text("Default Pools"), footer: Text("Select pools to be used as default. Must have at least one.")) {
                    if viewModel.pools.isEmpty {
                        Text("No origin pools available in this account.")
                            .foregroundStyle(.secondary)
                            .font(HIGTypography.caption)
                    } else {
                        ForEach(viewModel.pools) { pool in
                            Button(action: {
                                HIGFeedback.selection()
                                if selectedPools.contains(pool.id) {
                                    selectedPools.remove(pool.id)
                                } else {
                                    selectedPools.insert(pool.id)
                                }
                            }) {
                                HStack {
                                    Text(pool.name ?? pool.id)
                                        .font(HIGTypography.body)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedPools.contains(pool.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.higAccent)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .higTouchTarget(44)
                        }
                    }
                }
                
                if !viewModel.pools.isEmpty {
                    Section(header: Text("Fallback Pool"), footer: Text("Traffic will be routed here if all default pools fail.")) {
                        Picker("Select Fallback Pool", selection: $fallbackPool) {
                            Text("None Selected").tag("")
                            ForEach(viewModel.pools) { pool in
                                Text(verbatim: pool.name ?? pool.id).tag(pool.id)
                            }
                        }
                    }
                }
                
                if let error = viewModel.errorMessage, !error.isEmpty {
                    Section {
                        Text(verbatim: error)
                            .foregroundStyle(HIGColors.error)
                            .font(HIGTypography.caption)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create Load Balancer")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(HIGTypography.body)
                    .higTouchTarget()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSubmitting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save")
                                .font(HIGTypography.body.weight(.semibold))
                                .foregroundStyle(Color.higAccent)
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                    .higTouchTarget()
                }
            }
            .interactiveDismissDisabled(isSubmitting)
        }
        .higToast()
    }
    
    private func save() {
        isSubmitting = true
        HIGFeedback.impact(.medium)
        
        let poolsArray = Array(selectedPools)
        
        let payload = LoadBalancerUpdate(
            name: name.trimmingCharacters(in: .whitespaces),
            enabled: enabled,
            ttl: proxied ? nil : Int(ttl),
            proxied: proxied,
            defaultPools: poolsArray,
            fallbackPool: fallbackPool,
            steeringPolicy: steeringPolicy,
            sessionAffinity: sessionAffinity
        )
        
        Task {
            let success = await viewModel.createLoadBalancer(payload: payload)
            isSubmitting = false
            if success {
                HIGFeedback.success()
                ToastManager.shared.showSuccess("Load Balancer Created", icon: "arrow.triangle.branch")
                dismiss()
            } else {
                HIGFeedback.error()
            }
        }
    }
}
