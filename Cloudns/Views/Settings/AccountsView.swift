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
                            HIGFeedback.impact(.light)
                            withAnimation {
                                accountManager.switchAccount(to: email)
                                HIGFeedback.success()
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(email)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    if accountManager.activeEmail == email {
                                        HIGBadge(.custom(color: .orange, text: "Current"), isCompact: true)
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
                        HIGFeedback.impact(.light)
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
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                }
            }
            .sheet(isPresented: $isShowingAddAccount) {
                LoginView(onLoginSuccess: {
                    isShowingAddAccount = false
                    HIGFeedback.success()
                })
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func deleteAccount(at offsets: IndexSet) {
        let emails = accountManager.accountEmails
        HIGFeedback.impact(.medium)
        withAnimation {
            for index in offsets {
                let email = emails[index]
                accountManager.removeAccount(email: email)
                HIGFeedback.success()
            }
        }
    }
}
