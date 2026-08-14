import SwiftUI

struct AccountsView: View {
    @StateObject private var accountManager = AccountManager.shared
    @State private var isShowingAddAccount = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Logged In Accounts")) {
                    ForEach(Array(accountManager.accounts.keys), id: \.self) { email in
                        Button(action: {
                            withAnimation {
                                accountManager.switchAccount(to: email)
                                ToastManager.shared.showSuccess("Switched Account", message: email)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(email)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    if accountManager.activeEmail == email {
                                        Text("Current")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Spacer()
                                
                                if accountManager.activeEmail == email {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteAccount)
                }
                
                Section {
                    Button(action: {
                        isShowingAddAccount = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                            Text("Add Another Account")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .sheet(isPresented: $isShowingAddAccount) {
                LoginView(onLoginSuccess: {
                    isShowingAddAccount = false
                    ToastManager.shared.showSuccess("Account Added")
                })
            }
        }
    }
    
    private func deleteAccount(at offsets: IndexSet) {
        let keys = Array(accountManager.accounts.keys)
        withAnimation {
            for index in offsets {
                let email = keys[index]
                accountManager.removeAccount(email: email)
                ToastManager.shared.showSuccess("Account Removed", message: email)
            }
        }
    }
}
