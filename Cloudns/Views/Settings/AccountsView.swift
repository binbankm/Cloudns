import SwiftUI

struct AccountsView: View {
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var isShowingAddAccount = false
    @State private var emailToRemove: String?
    @State private var showingRemoveAccountAlert = false
    @Environment(\.dismiss) private var dismiss
    
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
                    Section(header: Text("Other Saved Accounts (\(otherEmails.count))"), footer: Text("Tap any account to instantly switch your active Cloudflare dashboard context.")) {
                        ForEach(otherEmails, id: \.self) { email in
                            Button {
                                switchAccount(to: email)
                            } label: {
                                accountRow(email: email, isActive: false)
                            }
                            .buttonStyle(.higPressable)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    emailToRemove = email
                                    showingRemoveAccountAlert = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                                .tint(HIGColors.error)
                            }
                        }
                    }
                }
                
                // 3. Add Account Action
                Section {
                    Button {
                        HIGFeedback.impact(.light)
                        isShowingAddAccount = true
                    } label: {
                        HStack(spacing: HIGTokens.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.higAccentSubtle)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.badge.plus")
                                    .font(HIGTypography.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.higAccent)
                            }
                            
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                Text("Add Another Account")
                                    .font(HIGTypography.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                Text("Manage multiple Cloudflare organizations")
                                    .font(HIGTypography.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(HIGTypography.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.higPressable)
                }
                
                // 4. Security & Keychain Footer Section
                Section {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "lock.shield.fill")
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("All API keys and tokens are securely stored in the iOS Keychain with hardware-level Secure Enclave encryption.")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, HIGTokens.Spacing.xs)
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
                    .font(HIGTypography.body.weight(.semibold))
                    .foregroundStyle(Color.higAccent)
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
                    HIGFeedback.destructive()
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
        HStack(spacing: HIGTokens.Spacing.md) {
            AccountAvatarView(identifier: email, size: 46)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                HStack(spacing: HIGTokens.Spacing.xs) {
                    Text(email)
                        .font(HIGTypography.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                    
                    Button {
                        HIGFeedback.copied()
                        UIPasteboard.general.string = email
                        ToastManager.shared.showCopied()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(HIGTypography.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.higPressable)
                    .higTouchTarget()
                }
                
                HStack(spacing: HIGTokens.Spacing.xs) {
                    HIGBadge(.active("Active"), isCompact: true)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    let key = accountManager.getAPIKey(for: email) ?? ""
                    let isToken = key.count > 37 || key.contains("_")
                    HIGBadge(.proxied(isToken ? "API Token" : "Global Key"), isCompact: true)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            
            Spacer(minLength: HIGTokens.Spacing.xs)
            
            Image(systemName: "checkmark.circle.fill")
                .font(HIGTypography.title3)
                .foregroundStyle(Color.higAccent)
                .accessibilityLabel("Current Active Account")
        }
        .padding(.vertical, HIGTokens.Spacing.xs)
    }
    
    // MARK: - Account Row
    @ViewBuilder
    private func accountRow(email: String, isActive: Bool) -> some View {
        HStack(spacing: HIGTokens.Spacing.md) {
            AccountAvatarView(identifier: email, size: 34)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(email)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                let key = accountManager.getAPIKey(for: email) ?? ""
                let isToken = key.count > 37 || key.contains("_")
                Text(isToken ? "Scoped API Token" : "Global API Key")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("Switch")
                .font(HIGTypography.caption.weight(.semibold))
                .foregroundStyle(Color.higAccent)
                .padding(.horizontal, HIGTokens.Spacing.md)
                .padding(.vertical, HIGTokens.Spacing.xs)
                .background(Color.higAccentSubtle)
                .clipShape(Capsule())
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
        .contentShape(Rectangle())
    }
    
    private func switchAccount(to email: String) {
        HIGFeedback.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            accountManager.switchAccount(to: email)
            ToastManager.shared.showSuccess("Switched to \(email)", icon: "person.crop.circle.badge.checkmark")
        }
    }
}
