import SwiftUI

struct SettingsView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("themePreference") private var themePreference = "system"
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    @State private var showingLogoutAlert = false
    @StateObject private var accountManager = AccountManager.shared
    
    // Cloudflare uses Gravatar for profile pictures based on email
    // But for simplicity, we use a placeholder or system image.
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Section
                Section {
                    NavigationLink(destination: AccountsView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 60, height: 60)
                                
                                Text(accountManager.activeEmail.prefix(1).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Accounts")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(accountManager.activeEmail)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // MARK: - Security Section
                Section {
                    Toggle(isOn: $isAppLockEnabled) {
                        SettingsRowView(
                            icon: "faceid",
                            color: .green,
                            title: "App Lock"
                        )
                    }
                    .onChange(of: isAppLockEnabled) { _ in
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                } header: {
                    Text("Security")
                } footer: {
                    Text("Require Face ID or Touch ID to unlock the app when returning from the background.")
                }
                
                // MARK: - Appearance Section
                Section {
                    Picker(selection: $themePreference) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    } label: {
                        SettingsRowView(
                            icon: "paintbrush.fill",
                            color: .orange,
                            title: "Theme"
                        )
                    }
                    .pickerStyle(.menu)
                    .onChange(of: themePreference) { _ in
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                } header: {
                    Text("Appearance")
                }
                
                // MARK: - Support & About Section
                Section {

                    Button(action: {
                        if let url = URL(string: "https://github.com/binbankm/Cloudns") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        SettingsRowView(
                            icon: "swift",
                            color: .black,
                            title: "GitHub Repository"
                        )
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        if let url = URL(string: "https://cloudflare.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        SettingsRowView(
                            icon: "shield.fill",
                            color: .blue,
                            title: "Privacy Policy"
                        )
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("About")
                } footer: {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    Text("Cloudns v\(version) (\(build))\nMade with ❤️ for Cloudflare users")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                // MARK: - Log Out Section
                Section {
                    Button(role: .destructive, action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    let loginVM = LoginViewModel()
                    loginVM.logout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to log out of your Cloudflare account?")
            }
        }
    }
}

// MARK: - Helper View for Settings Row
struct SettingsRowView: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
                    .frame(width: 30, height: 30)
                
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Text(title)
                .font(.body)
        }
    }
}

#Preview {
    SettingsView()
}
