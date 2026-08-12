import SwiftUI

struct SecuritySettingsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SecurityViewModel()
    @State private var showUnderAttackAlert = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Danger Zone: Under Attack Mode
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundColor(viewModel.securityLevel == "under_attack" ? .white : .red)
                                .font(.title2)
                            Text("I'm Under Attack Mode")
                                .font(.headline)
                                .foregroundColor(viewModel.securityLevel == "under_attack" ? .white : .red)
                            
                            Spacer()
                            
                            if viewModel.securityLevel == "under_attack" {
                                Text("ACTIVE")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .foregroundColor(.red)
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text("Use this only if your website is currently under a DDoS attack. Visitors will receive an interstitial page for a few seconds while we analyze their traffic and behavior to make sure they are a legitimate human visitor.")
                            .font(.subheadline)
                            .foregroundColor(viewModel.securityLevel == "under_attack" ? .white.opacity(0.9) : .secondary)
                        
                        Button(action: {
                            if viewModel.securityLevel == "under_attack" {
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
                            .foregroundColor(viewModel.securityLevel == "under_attack" ? .red : .white)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.hasFetchedData)
                    }
                    .padding()
                    .background(viewModel.securityLevel == "under_attack" ? Color.red : Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(color: viewModel.securityLevel == "under_attack" ? Color.red.opacity(0.3) : Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    
                    // General Security Settings
                    VStack(spacing: 0) {
                        
                        // Security Level
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Security Level")
                                    .font(.body)
                                Text("Adjust your website's security level to determine who will receive a challenge page.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Picker("Security Level", selection: $viewModel.securityLevel) {
                                Text("Essentially Off").tag("essentially_off")
                                Text("Low").tag("low")
                                Text("Medium").tag("medium")
                                Text("High").tag("high")
                                Text("Under Attack").tag("under_attack")
                            }
                            .pickerStyle(.menu)
                            .onChange(of: viewModel.securityLevel) { newValue in
                                Task {
                                    await viewModel.updateSecurityLevel(zoneId: zoneId, level: newValue)
                                }
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Challenge Passage (TTL)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Challenge Passage")
                                    .font(.body)
                                Text("How long a visitor is allowed access after successfully completing a challenge.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
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
                            .onChange(of: viewModel.challengeTTL) { newValue in
                                Task {
                                    await viewModel.updateChallengeTTL(zoneId: zoneId, ttl: newValue)
                                }
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Browser Integrity Check
                        Toggle(isOn: $viewModel.browserCheck) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Browser Integrity Check")
                                    .font(.body)
                                Text("Evaluate HTTP headers from your visitors browser for threats.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.browserCheck) { newValue in
                            Task {
                                await viewModel.updateBrowserCheck(zoneId: zoneId, isOn: newValue)
                            }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Bot Fight Mode
                        Toggle(isOn: $viewModel.botFightMode) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("Bot Fight Mode")
                                        .font(.body)
                                    Image(systemName: "ant.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                Text("Detects and challenges known bots and crawlers. Recommended for most sites.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: viewModel.botFightMode) { newValue in
                            Task {
                                await viewModel.updateBotFightMode(zoneId: zoneId, isOn: newValue)
                            }
                        }
                        .padding()
                        
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    
                }
                .padding()
                .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
                .disabled(!viewModel.hasFetchedData)
            }
            .refreshable {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings(zoneId: zoneId)
            }
        }
        .alert("Enable Under Attack Mode?", isPresented: $showUnderAttackAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Enable", role: .destructive) {
                Task {
                    await viewModel.updateSecurityLevel(zoneId: zoneId, level: "under_attack")
                    
                    let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
                }
            }
        } message: {
            Text("Are you sure you want to enable I'm Under Attack Mode? All visitors will be challenged. This may negatively impact legitimate traffic.")
        }
    }
}
