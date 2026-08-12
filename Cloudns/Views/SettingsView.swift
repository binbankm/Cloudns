import SwiftUI

struct SettingsView: View {
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("themePreference") private var themePreference = "system"
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    @State private var showingLogoutAlert = false
    @State private var userEmail: String = "Loading..."
    
    // Cloudflare uses Gravatar for profile pictures based on email
    // But for simplicity, we use a placeholder or system image.
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Section
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                            
                            Text(userEmail.prefix(1).uppercased())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cloudflare Account")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
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
                } header: {
                    Text("Appearance")
                }
                
                // MARK: - Support & About Section
                Section {
                    Button(action: {
                        // Action for rating app
                    }) {
                        SettingsRowView(
                            icon: "star.fill",
                            color: .yellow,
                            title: "Rate Cloudns"
                        )
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        SettingsRowView(
                            icon: "chevron.left.forwardslash.chevron.right",
                            color: .gray,
                            title: "Open Source Licenses"
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
            .onAppear {
                fetchUserEmail()
            }
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out of your Cloudflare account?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        let loginVM = LoginViewModel()
                        loginVM.logout()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func fetchUserEmail() {
        let service = CloudflareAPIClient.shared.serviceName
        if let email = KeychainHelper.standard.readString(service: service, account: "email") {
            self.userEmail = email
        } else {
            self.userEmail = "Unknown User"
        }
    }
}

// MARK: - Helper View for Settings Row
struct SettingsRowView: View {
    let icon: String
    let color: Color
    let title: String
    
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
