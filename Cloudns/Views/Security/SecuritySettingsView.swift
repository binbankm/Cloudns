import SwiftUI

// MARK: - SecuritySettingsView
// Apple HIG Compliant Cloudflare Threat Defense, Security Level & Bot Management

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
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.red)
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
                            HapticManager.selection()
                            Task {
                                await viewModel.updateSecurityLevel(zoneId: zoneId, level: "medium")
                                ToastManager.shared.showSuccess("Under Attack Mode Disabled", icon: "shield.slash")
                            }
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "flame.fill", color: .red)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("I'm Under Attack Mode™")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(isUnderAttack ? Color.red : .primary)
                                if isUnderAttack {
                                    Text("Active")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(Color.red)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.red.opacity(0.12)))
                                }
                            }
                            Text("Perform deep DDoS verification on all incoming visitors.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(Color.red)
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Standard Threat Defense
            Section(
                header: Text("Threat Defense Level"),
                footer: Text("Adjust the sensitivity threshold for presenting challenge pages to suspicious visitors.")
            ) {
                // Security Level
                HStack(spacing: 12) {
                    ListRowIcon(icon: "shield.lefthalf.filled", color: .blue)
                    VStack(alignment: .leading, spacing: 2) {
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
                            HapticManager.selection()
                            Task {
                                await viewModel.updateSecurityLevel(zoneId: zoneId, level: val)
                                ToastManager.shared.showSuccess("Security Level Updated", icon: "shield.lefthalf.filled")
                            }
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
                    ListRowIcon(icon: "hourglass", color: .orange)
                    VStack(alignment: .leading, spacing: 2) {
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
                            HapticManager.selection()
                            Task {
                                await viewModel.updateChallengeTTL(zoneId: zoneId, ttl: val)
                                ToastManager.shared.showSuccess("Challenge TTL Updated", icon: "hourglass")
                            }
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateBrowserCheck(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess("Browser Integrity Check Updated", icon: "checkmark.shield")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "checkmark.shield.fill", color: .teal)
                        VStack(alignment: .leading, spacing: 2) {
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
                        HapticManager.selection()
                        Task {
                            await viewModel.updateBotFightMode(zoneId: zoneId, isOn: val)
                            ToastManager.shared.showSuccess("Bot Fight Mode Updated", icon: "cpu.fill")
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "cpu.fill", color: .purple)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Bot Fight Mode")
                                    .font(.body)
                                Text("Free")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Security Settings…",
            error: !viewModel.hasFetchedData && !viewModel.isLoading ? viewModel.errorMessage : nil,
            onRetry: { Task { await viewModel.fetchSettings(zoneId: zoneId) } }
        )
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
                    ToastManager.shared.showSuccess("Under Attack Mode Enabled", icon: "flame.fill")
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
