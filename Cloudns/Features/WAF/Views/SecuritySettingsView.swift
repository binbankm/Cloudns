import SwiftUI

struct SecuritySettingsView: View {
    // MARK: - Properties
    let zoneId: String
    
    @StateObject private var viewModel = SecurityViewModel()
    @State private var showUnderAttackAlert = false
    
    // MARK: - Body
    var body: some View {
        List {
            if viewModel.hasFetchedData {
                // Danger Zone: Under Attack Mode
                Section(header: Text("Danger Zone")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundStyle(viewModel.securityLevel == "under_attack" ? .white : .red)
                                .font(.title2)
                                .accessibilityHidden(true)
                            Text("I'm Under Attack Mode")
                                .font(.body.weight(.medium))
                                .foregroundStyle(viewModel.securityLevel == "under_attack" ? .white : .red)
                            
                            Spacer()
                            
                            if viewModel.securityLevel == "under_attack" {
                                CloudnsBadge(.error("ACTIVE"), isCompact: true)
                            }
                        }
                        
                        Text("Use this only if your website is currently under a DDoS attack. Visitors will receive an interstitial page for a few seconds while we analyze their traffic and behavior to make sure they are a legitimate human visitor.")
                            .font(.caption)
                            .foregroundStyle(viewModel.securityLevel == "under_attack" ? .white.opacity(0.9) : .secondary)
                        
                        Button(action: {
                            if viewModel.securityLevel == "under_attack" {
                                HapticManager.impact(.medium)
                                Task {
                                    await viewModel.updateSecurityLevel(zoneId: zoneId, level: "medium")
                                }
                            } else {
                                showUnderAttackAlert = true
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text(viewModel.securityLevel == "under_attack" ? "Disable Under Attack Mode" : "Enable Under Attack Mode")
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .padding()
                            .background(viewModel.securityLevel == "under_attack" ? Color.white : Color.red)
                            .foregroundStyle(viewModel.securityLevel == "under_attack" ? .red : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.hasFetchedData)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(viewModel.securityLevel == "under_attack" ? Color.red : Color(.secondarySystemGroupedBackground))
            
            // General Security Settings
            Section(header: Text("General Security")) {
                // Security Level
                VStack(alignment: .leading, spacing: 4) {
                    Text("Security Level")
                        .font(.body)
                    Text("Adjust your website's security level to determine who will receive a challenge page.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Security Level", selection: Binding(
                        get: { viewModel.securityLevel },
                        set: { newValue in
                            Task { await viewModel.updateSecurityLevel(zoneId: zoneId, level: newValue) }
                        }
                    )) {
                        Text("Essentially Off").tag("essentially_off")
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                        Text("Under Attack").tag("under_attack")
                    }
                    .pickerStyle(.menu)
                    .disabled(!viewModel.hasFetchedData)
                }
                
                // Challenge Passage (TTL)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenge Passage")
                        .font(.body)
                    Text("How long a visitor is allowed access after successfully completing a challenge.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("TTL", selection: Binding(
                        get: { viewModel.challengeTTL },
                        set: { newValue in
                            Task { await viewModel.updateChallengeTTL(zoneId: zoneId, ttl: newValue) }
                        }
                    )) {
                        Text("5 minutes").tag(300)
                        Text("15 minutes").tag(900)
                        Text("30 minutes").tag(1800)
                        Text("1 hour").tag(3600)
                        Text("2 hours").tag(7200)
                        Text("4 hours").tag(14400)
                        Text("1 day").tag(86400)
                        Text("1 week").tag(604800)
                        Text("1 month").tag(2592000)
                        Text("1 year").tag(31536000)
                    }
                    .pickerStyle(.menu)
                    .disabled(!viewModel.hasFetchedData)
                }
                
                // Browser Integrity Check
                Toggle(isOn: Binding(
                    get: { viewModel.browserCheck },
                    set: { newValue in
                        Task { await viewModel.updateBrowserCheck(zoneId: zoneId, isOn: newValue) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Browser Integrity Check")
                            .font(.body)
                        Text("Evaluate HTTP headers from your visitors browser for threats.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Bot Fight Mode
                Toggle(isOn: Binding(
                    get: { viewModel.botFightMode },
                    set: { newValue in
                        Task { await viewModel.updateBotFightMode(zoneId: zoneId, isOn: newValue) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Bot Fight Mode")
                                .font(.body)
                            Image(systemName: "ant.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            CloudnsBadge(.free, isCompact: true)
                        }
                        Text("Detects and challenges known bots and crawlers. Recommended for most sites.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
        } else if viewModel.isLoading {
            Section(header: Text("Security Level")) {
                Picker("Security Level", selection: .constant("medium")) {
                    Text("Medium").tag("medium")
                }
                .skeletonLoading(true)
            }
            Section(header: Text("Browser Integrity Check")) {
                Toggle(isOn: .constant(true)) {
                    Text("Browser Integrity Check")
                }
                .skeletonLoading(true)
            }
        }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData && !viewModel.isLoading {
                CloudnsStateOverlayView(
                    state: .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: { Task { await viewModel.fetchSettings(zoneId: zoneId) } }
                    )
                )
            }
        }
        .refreshable {
            await viewModel.fetchSettings(zoneId: zoneId)
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
        .confirmationDialog("Enable Under Attack Mode?", isPresented: $showUnderAttackAlert, titleVisibility: .visible) {
            Button("Enable Under Attack Mode", role: .destructive) {
                Task {
                    HapticManager.notification(.warning)
                    await viewModel.updateSecurityLevel(zoneId: zoneId, level: "under_attack")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to enable I'm Under Attack Mode? All visitors will be challenged. This may negatively impact legitimate traffic.")
        }
    }
}
