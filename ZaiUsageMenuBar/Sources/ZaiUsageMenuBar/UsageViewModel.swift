import SwiftUI
import Foundation

@MainActor
class UsageViewModel: ObservableObject {
    @Published var dashboard: UsageDashboardData?
    @Published var isLoading = false
    @Published var error: String?

    func refresh() {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        Task {
            let accounts = AccountConfigStore.loadAccounts()
            let enabledAccounts = accounts.filter { $0.isEnabled && !$0.authToken.trimmed.isEmpty }

            guard !enabledAccounts.isEmpty else {
                self.dashboard = nil
                self.error = L10n.localized("no_accounts_configured")
                AppDelegate.shared?.updateStatusItem(percentage: nil)
                self.isLoading = false
                return
            }

            let accountResults = await UsageAPIClient.shared.fetchAllUsage(accounts: enabledAccounts)
            let now = Date()

            self.dashboard = UsageDashboardData(accounts: accountResults, lastUpdated: now)

            let firstSuccessfulUsage = accountResults.first { $0.usage != nil }
            if firstSuccessfulUsage == nil {
                self.error = L10n.localized("all_accounts_failed")
                AppDelegate.shared?.updateStatusItem(percentage: nil)
            } else {
                self.error = nil
                AppDelegate.shared?.updateStatusItem(
                    percentage: UsageAggregation.tokenPercentage(from: firstSuccessfulUsage?.usage?.quotaLimits)
                )
            }

            self.isLoading = false
        }
    }
}
