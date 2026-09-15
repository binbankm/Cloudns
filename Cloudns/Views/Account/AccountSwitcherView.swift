import SwiftUI

// MARK: - AccountSwitcherView (Gentle Half-Sheet Multi-Account Drawer)

struct AccountSwitcherView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AccountSwitcherViewModel

    init(viewModel: AccountSwitcherViewModel = AccountSwitcherViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                GentleSheetHeader(
                    title: "Accounts",
                    subtitle: "Select active credentials",
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
                                GentleHaptics.selection()
                            } label: {
                                HStack(spacing: GentleSpacing.sm) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(GentleTypography.bodyMedium)
                                    Text("Add Account")
                                        .font(GentleTypography.buttonLabel)
                                }
                                .foregroundStyle(GentleColor.accent)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(GentleColor.cardSurface)
                                .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.xl, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: GentleCornerRadius.xl, style: .continuous)
                                        .stroke(GentleColor.accent.opacity(0.3), lineWidth: 1)
                                )
                            }
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
                VStack(alignment: .leading, spacing: 2) {
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
            .padding(GentleSpacing.md)
            .background(GentleColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GentleCornerRadius.lg, style: .continuous)
                    .stroke(
                        isActive ? GentleColor.accent.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: Color.black.opacity(0.035),
                radius: 8,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteAccount(id: account.id)
            } label: {
                Label("Remove Account", systemImage: "trash")
            }
        }
    }
}

#Preview {
    AccountSwitcherView()
}
