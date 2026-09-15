import Combine
import Foundation

// MARK: - Account Switcher ViewModel (AGENTS.md MVVM)

@MainActor
final class AccountSwitcherViewModel: ObservableObject {
    @Published private(set) var accounts: [CloudflareAccount] = []
    @Published private(set) var activeAccountId: String?
    @Published var showAddAccountSheet: Bool = false

    private let accountManager: AccountManager
    private var cancellables = Set<AnyCancellable>()

    init(accountManager: AccountManager = AccountManager.shared) {
        self.accountManager = accountManager
        bindAccountManager()
    }

    private func bindAccountManager() {
        accountManager.$accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedAccounts in
                self?.accounts = updatedAccounts
            }
            .store(in: &cancellables)

        accountManager.$activeAccountId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedId in
                self?.activeAccountId = updatedId
            }
            .store(in: &cancellables)
    }

    var activeAccount: CloudflareAccount? {
        accountManager.currentAccount
    }

    func switchAccount(to id: String) {
        guard activeAccountId != id else { return }
        accountManager.switchAccount(to: id)
    }

    func deleteAccount(id: String) {
        accountManager.deleteAccount(id: id)
    }
}
