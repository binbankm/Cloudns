import SwiftUI

struct SecuritySettingsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SecurityViewModel()
    @State private var showUnderAttackAlert = false
    
    var body: some View {
        List {
            // MARK: - Hero Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.18), Color.orange.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "shield.checkerboard")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 4)
                    
                    Text("Security Settings")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Configure threat defense, visitor challenges, and bot protection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // MARK: - Emergency Defense
            Section(
                header: Text("Emergency Defense"),
                footer: Text("Under Attack Mode executes JS challenges for every visitor to stop active DDoS attacks.")
            ) {
                let isUnderAttack = viewModel.securityLevel == "under_attack"
                
                Toggle(isOn: Binding(
                    get: { isUnderAttack },
                    set: { enabled in
                        if enabled {
                            showUnderAttackAlert = true
                        } else {
                            HIGFeedback.selection()
                            Task {
                                await viewModel.updateSecurityLevel(zoneId: zoneId, level: "medium")
                            }
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "flame.fill", color: .red, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("I'm Under Attack Mode™")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(isUnderAttack ? .red : .primary)
                                if isUnderAttack {
                                    HIGBadge(.error("Active"), isCompact: true)
                                }
                            }
                            Text("Perform deep DDoS verification on all incoming visitors.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.red)
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Standard Threat Defense
            Section(
                header: Text("Threat Defense Level"),
                footer: Text("Adjust the sensitivity threshold for presenting challenge pages to suspicious visitors.")
            ) {
                // Security Level
                HStack(spacing: 12) {
                    ListRowIcon(icon: "shield.lefthalf.filled", color: .blue, size: 28, cornerRadius: 6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Security Level")
                            .font(.body)
                        Text(securityLevelDescription(viewModel.securityLevel))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Security Level", selection: Binding(
                        get: { viewModel.securityLevel },
                        set: { val in
                            HIGFeedback.selection()
                            Task { await viewModel.updateSecurityLevel(zoneId: zoneId, level: val) }
                        }
                    )) {
                        Text("Essentially Off").tag("essentially_off")
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Challenge TTL
                HStack(spacing: 12) {
                    ListRowIcon(icon: "hourglass", color: .orange, size: 28, cornerRadius: 6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Challenge Passage TTL")
                            .font(.body)
                        Text("How long a visitor can access site after passing challenge.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Challenge Passage TTL", selection: Binding(
                        get: { viewModel.challengeTTL },
                        set: { val in
                            HIGFeedback.selection()
                            Task { await viewModel.updateChallengeTTL(zoneId: zoneId, ttl: val) }
                        }
                    )) {
                        Text("5 mins").tag(300)
                        Text("15 mins").tag(900)
                        Text("30 mins").tag(1800)
                        Text("45 mins").tag(2700)
                        Text("1 hour").tag(3600)
                        Text("2 hours").tag(7200)
                        Text("1 day").tag(86400)
                        Text("1 year").tag(31536000)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .disabled(!viewModel.hasFetchedData)
                
                // Browser Integrity Check
                Toggle(isOn: Binding(
                    get: { viewModel.browserCheck },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateBrowserCheck(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "checkmark.shield.fill", color: .teal, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Browser Integrity Check")
                                .font(.body)
                            Text("Inspect HTTP headers for known malicious web scrapers.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Bot Protection
            Section(
                header: Text("Bot Defense"),
                footer: Text("Cloudflare Bot Fight Mode matches IP reputation and behavioral analysis to block automated attack bots.")
            ) {
                Toggle(isOn: Binding(
                    get: { viewModel.botFightMode },
                    set: { val in
                        HIGFeedback.selection()
                        Task { await viewModel.updateBotFightMode(zoneId: zoneId, isOn: val) }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "cpu.fill", color: .purple, size: 28, cornerRadius: 6)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("Bot Fight Mode")
                                    .font(.body)
                                HIGBadge(.free, isCompact: true)
                            }
                            Text("Detects and challenges automated scrapers and malicious crawlers.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Security Settings…"))
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData && !viewModel.isLoading {
                HIGContentState(
                    .error(
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
                    HIGFeedback.warning()
                    await viewModel.updateSecurityLevel(zoneId: zoneId, level: "under_attack")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to enable I'm Under Attack Mode? All visitors will receive challenge pages.")
        }
    }
    
    private func securityLevelDescription(_ level: String) -> LocalizedStringKey {
        switch level {
        case "essentially_off": return "Essentially Off"
        case "low": return "Low (Fewest challenges)"
        case "medium": return "Medium (Balanced)"
        case "high": return "High (Most secure)"
        case "under_attack": return "I'm Under Attack!"
        default: return "Configuring…"
        }
    }
}
