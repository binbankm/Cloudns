import SwiftUI

// MARK: - AccountsView
// Apple HIG Compliant Multi-Account Switcher & Authentication Vault (iOS 16.0+)

struct AccountsView: View {
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var isShowingAddAccount = false
    @State private var emailToRemove: String?
    @State private var showingRemoveAccountAlert = false
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var accentColor: Color {
        themeManager.currentColor.color
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 1. Current Active Hero Section
                if !accountManager.activeEmail.isEmpty {
                    Section(header: Text("Active Account")) {
                        activeAccountHeroRow(email: accountManager.activeEmail)
                    }
                }
                
                // 2. Other Accounts Switcher
                let otherEmails = accountManager.accountEmails.filter { $0 != accountManager.activeEmail }
                if !otherEmails.isEmpty {
                    Section(
                        header: Text("Other Saved Accounts (\(otherEmails.count))"),
                        footer: Text("Tap any account to instantly switch your active Cloudflare dashboard context.")
                    ) {
                        ForEach(otherEmails, id: \.self) { email in
                            Button {
                                switchAccount(to: email)
                            } label: {
                                accountRow(email: email, isActive: false)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    emailToRemove = email
                                    showingRemoveAccountAlert = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
                
                // 3. Add Account Action
                Section {
                    Button {
                        HapticManager.impact(.light)
                        isShowingAddAccount = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(accentColor.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.badge.plus")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add Another Account")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                Text("Manage multiple Cloudflare organizations")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                // 4. Security & Keychain Footer Section
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("All API keys and tokens are securely stored in the iOS Keychain with hardware-level Secure Enclave encryption.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor)
                }
            }
            .sheet(isPresented: $isShowingAddAccount) {
                LoginView(onLoginSuccess: {
                    isShowingAddAccount = false
                    ToastManager.shared.showSuccess("Account Added", icon: "person.crop.circle.badge.plus")
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog("Remove Account", isPresented: $showingRemoveAccountAlert, titleVisibility: .visible, presenting: emailToRemove) { email in
                Button("Remove '\(email)'", role: .destructive) {
                    HapticManager.notification(.warning)
                    withAnimation {
                        accountManager.removeAccount(email: email)
                        ToastManager.shared.showSuccess("Account Removed", icon: "person.crop.circle.badge.minus")
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { email in
                Text("Are you sure you want to remove account '\(email)'? You will need to re-authenticate to access its domains and services.")
            }
        }
    }
    
    // MARK: - Active Account Hero Row
    @ViewBuilder
    private func activeAccountHeroRow(email: String) -> some View {
        HStack(spacing: 12) {
            AccountAvatarView(identifier: email, size: 46)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(email)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                    
                    Button {
                        copyToClipboard(email, toast: "Account Email Copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 6) {
                    Text("Active")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.14))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                    
                    let key = accountManager.getAPIKey(for: email) ?? ""
                    let isToken = key.count > 37 || key.contains("_")
                    Text(isToken ? LocalizedStringKey("API Token") : LocalizedStringKey("Global Key"))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.14))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
            
            Spacer(minLength: 6)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(accentColor)
                .accessibilityLabel("Current Active Account")
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Account Row
    @ViewBuilder
    private func accountRow(email: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            AccountAvatarView(identifier: email, size: 34)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(email)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                let key = accountManager.getAPIKey(for: email) ?? ""
                let isToken = key.count > 37 || key.contains("_")
                Text(isToken ? LocalizedStringKey("Scoped API Token") : LocalizedStringKey("Global API Key"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("Switch")
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
    
    private func switchAccount(to email: String) {
        HapticManager.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            accountManager.switchAccount(to: email)
            ToastManager.shared.showSuccess("Switched to \(email)", icon: "person.crop.circle.badge.checkmark")
        }
    }
}
