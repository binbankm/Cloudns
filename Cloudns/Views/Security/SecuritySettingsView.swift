import SwiftUI

struct SecuritySettingsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SecurityViewModel()
    @State private var showUnderAttackAlert = false
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData {
                // Skeleton: Danger Zone Placeholder
                Section(header: Text("Danger Zone")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SkeletonBar(width: 32, height: 32, cornerRadius: 8)
                            SkeletonBar(width: 160, height: 18, cornerRadius: 4)
                            Spacer()
                        }
                        SkeletonBar(height: 12, cornerRadius: 4)
                        SkeletonBar(height: 12, cornerRadius: 4)
                        SkeletonBar(width: 200, height: 12, cornerRadius: 4)
                        
                        SkeletonBar(height: 48, cornerRadius: 10)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    .skeletonLoading(true)
                }
                
                // Skeleton: General Security Placeholder
                Section(header: Text("General Security")) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                SkeletonBar(width: 140, height: 16, cornerRadius: 4)
                                SkeletonBar(width: 220, height: 12, cornerRadius: 4)
                            }
                            Spacer()
                            SkeletonBar(width: 50, height: 30, cornerRadius: 15)
                        }
                        .padding(.vertical, 6)
                        .skeletonLoading(true)
                    }
                }
            } else {
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
                                Text("ACTIVE")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .foregroundStyle(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
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
                    
                    Picker("Security Level", selection: $viewModel.securityLevel) {
                        Text("Essentially Off").tag("essentially_off")
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                        Text("Under Attack").tag("under_attack")
                    }
                    .pickerStyle(.menu)
                    .disabled(!viewModel.hasFetchedData)
                    .onChange(of: viewModel.securityLevel) { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HapticManager.impact(.light)
                        Task {
                            await viewModel.updateSecurityLevel(zoneId: zoneId, level: newValue)
                        }
                    }
                }
                
                // Challenge Passage (TTL)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Challenge Passage")
                        .font(.body)
                    Text("How long a visitor is allowed access after successfully completing a challenge.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("TTL", selection: $viewModel.challengeTTL) {
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
                    .onChange(of: viewModel.challengeTTL) { newValue in
                        guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                        HapticManager.impact(.light)
                        Task {
                            await viewModel.updateChallengeTTL(zoneId: zoneId, ttl: newValue)
                        }
                    }
                }
                
                // Browser Integrity Check
                Toggle(isOn: $viewModel.browserCheck) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Browser Integrity Check")
                            .font(.body)
                        Text("Evaluate HTTP headers from your visitors browser for threats.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.browserCheck) { newValue in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.updateBrowserCheck(zoneId: zoneId, isOn: newValue)
                    }
                }
                
                // Bot Fight Mode
                Toggle(isOn: $viewModel.botFightMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Bot Fight Mode")
                                .font(.body)
                            Image(systemName: "ant.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                        }
                        Text("Detects and challenges known bots and crawlers. Recommended for most sites.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!viewModel.hasFetchedData)
                .onChange(of: viewModel.botFightMode) { newValue in
                    guard viewModel.hasFetchedData && !viewModel.isLoading else { return }
                    HapticManager.impact(.light)
                    Task {
                        await viewModel.updateBotFightMode(zoneId: zoneId, isOn: newValue)
                    }
                }
            }
        }
    }
    .listStyle(.insetGrouped)
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
        .animation(.easeInOut(duration: 0.3), value: viewModel.securityLevel)
        .overlay {
            if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData && !viewModel.isLoading {
                StateOverlayView(
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
        .toastContainer()
    }
}
