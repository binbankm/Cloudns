import SwiftUI

struct AccountsView: View {
    @ObservedObject private var accountManager = AccountManager.shared
    @State private var isShowingAddAccount = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Logged In Accounts")) {
                    ForEach(accountManager.accountEmails, id: \.self) { email in
                        Button(action: {
                            HapticManager.impact(.light)
                            withAnimation {
                                accountManager.switchAccount(to: email)
                                ToastManager.shared.showSuccess("Switched Account", message: email)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(email)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    if accountManager.activeEmail == email {
                                        CloudnsBadge(.custom(color: .orange, text: "Current"), isCompact: true)
                                    }
                                }
                                
                                Spacer()
                                
                                if accountManager.activeEmail == email {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                        .font(.subheadline.weight(.semibold))
                                        .accessibilityHidden(true)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteAccount)
                }
                
                Section {
                    Button(action: {
                        HapticManager.impact(.light)
                        isShowingAddAccount = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            Text("Add Another Account")
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .listStyle(.insetGrouped)
            .centerConstrainedWidth(maxWidth: 840)
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                }
            }
            .sheet(isPresented: $isShowingAddAccount) {
                LoginView(onLoginSuccess: {
                    isShowingAddAccount = false
                    ToastManager.shared.showSuccess("Account Added")
                })
                .presentationDragIndicator(.visible)
            }
            .toastContainer()
        }
    }
    
    private func deleteAccount(at offsets: IndexSet) {
        let emails = accountManager.accountEmails
        HapticManager.impact(.medium)
        withAnimation {
            for index in offsets {
                let email = emails[index]
                accountManager.removeAccount(email: email)
                ToastManager.shared.showSuccess("Account Removed", message: email)
            }
        }
    }
}
