import SwiftUI

// MARK: - AccountSwitcherView (Gentle Half-Sheet Multi-Account Drawer)

struct AccountSwitcherView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AccountSwitcherViewModel()
    @State private var accountToDelete: CloudflareAccount?
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with Done button
                GentleSheetHeader(
                    title: "Switch Account",
                    trailingButtonTitle: "Done",
                    onTrailingAction: {
                        dismiss()
                    }
                )

                if viewModel.accounts.isEmpty {
                    GentleEmptyStateView(
                        iconName: "person.crop.circle.badge.plus",
                        title: "No Accounts",
                        message: "Add a Cloudflare account to get started.",
                        actionTitle: "Add Account",
                        action: {
                            viewModel.showAddAccountSheet = true
                        }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: GentleSpacing.md) {
                            // Account Cards List
                            VStack(spacing: GentleSpacing.sm) {
                                ForEach(viewModel.accounts) { account in
                                    let isActive = (account.id == viewModel.activeAccountId)
                                    accountRow(account: account, isActive: isActive)
                                }
                            }

                            // Add Another Account Button
                            Button {
                                viewModel.showAddAccountSheet = true
                            } label: {
                                HStack(spacing: GentleSpacing.xs) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(GentleTypography.bodyMedium)
                                    Text("Add Account")
                                }
                                .foregroundStyle(GentleColor.accent)
                            }
                            .gentleSecondaryButton(cornerRadius: GentleCornerRadius.xl, height: 50)
                            .padding(.top, GentleSpacing.xs)
                        }
                        .padding(GentleSpacing.lg)
                    }
                    .gentleCanvas()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $viewModel.showAddAccountSheet) {
            LoginView()
        }
        .confirmationDialog(
            "Remove Account",
            isPresented: $showDeleteConfirmation,
            presenting: accountToDelete
        ) { account in
            Button("Remove \(account.name)", role: .destructive) {
                viewModel.deleteAccount(id: account.id)
                if viewModel.accounts.isEmpty {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { account in
            if viewModel.accounts.count <= 1 {
                Text("Remove \(account.name)? You will be returned to the login screen.")
            } else {
                Text("Remove \(account.name)? Credentials will be deleted from this device.")
            }
        }
    }

    private func accountRow(account: CloudflareAccount, isActive: Bool) -> some View {
        Button {
            if !isActive {
                viewModel.switchAccount(to: account.id)
                GentleHaptics.selection()
                dismiss()
            }
        } label: {
            HStack(spacing: GentleSpacing.md) {
                // Avatar with deterministic color
                GentleAvatar(
                    name: account.name,
                    email: account.email,
                    size: .medium,
                    isActive: isActive
                )

                // Account Name & Email
                VStack(alignment: .leading, spacing: GentleSpacing.micro) {
                    Text(account.name)
                        .font(GentleTypography.subheadlineBold)
                        .foregroundStyle(GentleColor.textPrimary)
                        .lineLimit(1)

                    Text(account.email)
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Active badge or select indicator
                if isActive {
                    GentleBadge("Active", iconName: "checkmark", type: .active)
                } else {
                    Image(systemName: "chevron.right")
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary.opacity(0.4))
                }
            }
            .gentleCardStyle(
                variant: isActive ? .highlighted : .elevated,
                cornerRadius: GentleCornerRadius.lg,
                padding: GentleSpacing.md
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                accountToDelete = account
                showDeleteConfirmation = true
            } label: {
                Label("Remove Account", systemImage: "trash")
            }
        }
    }
}

#Preview {
    AccountSwitcherView()
}
