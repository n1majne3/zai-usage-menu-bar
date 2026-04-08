# Multi-Account UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the combined 汇总 section with per-account collapsible sections, each showing the full rich UI (配额, 模型用量, 工具调用).

**Architecture:** Remove aggregation logic entirely. Each account's API data renders directly into the same view components previously used for the combined section. A `DisclosureGroup`-style header toggles per-account visibility.

**Tech Stack:** SwiftUI, Swift Package Manager, XCTest

---

### Task 1: Remove CombinedUsageData and simplify UsageDashboardData

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageModels.swift`

- [ ] **Step 1: Update UsageModels.swift**

Remove `CombinedUsageData` struct. Simplify `UsageDashboardData` to not reference combined data:

```swift
struct UsageDashboardData {
    let accounts: [AccountUsageResult]
    let lastUpdated: Date
}
```

Delete the `CombinedUsageData` struct entirely (lines 101-105).

- [ ] **Step 2: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageModels.swift
git commit -m "refactor: remove CombinedUsageData, simplify UsageDashboardData"
```

---

### Task 2: Simplify UsageAggregation — remove combine methods, keep tokenPercentage

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageAggregation.swift`
- Modify: `ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/UsageAggregationTests.swift`

- [ ] **Step 1: Write failing test for per-account tokenPercentage**

In `UsageAggregationTests.swift`, add a test that calls `UsageAggregation.tokenPercentage(from:)` with a single account's `QuotaLimitData` directly:

```swift
func testTokenPercentageFromSingleAccountQuota() {
    let quotaData = QuotaLimitData(
        limits: [
            QuotaLimit(
                type: "TOKENS_LIMIT",
                unit: 1,
                number: 1,
                usage: 5000,
                currentValue: 500,
                remaining: 4500,
                percentage: 10,
                nextResetTime: 1_710_000_000_000,
                usageDetails: nil
            )
        ],
        level: "pro"
    )

    let percentage = UsageAggregation.tokenPercentage(from: quotaData)
    XCTAssertEqual(percentage ?? -1, 10, accuracy: 0.001)
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd ZaiUsageMenuBar && swift test --filter UsageAggregationTests/testTokenPercentageFromSingleAccountQuota`
Expected: PASS (this method already works per-account)

- [ ] **Step 3: Remove combine methods and all tests referencing combine**

In `UsageAggregation.swift`, remove everything except `tokenPercentage(from:)` and `percentage(for:)`. The file becomes:

```swift
import Foundation

enum UsageAggregation {
    static func tokenPercentage(from quotaLimits: QuotaLimitData?) -> Double? {
        let tokenLimit = quotaLimits?.limits?.first { $0.type == "TOKENS_LIMIT" }
        return percentage(for: tokenLimit)
    }

    private static func percentage(for limit: QuotaLimit?) -> Double? {
        guard let limit else { return nil }
        if let percentage = limit.percentage {
            return percentage
        }

        if let usage = limit.usage, usage > 0 {
            if let currentValue = limit.currentValue {
                return currentValue / usage * 100
            }
            if let remaining = limit.remaining {
                return max(min((usage - remaining) / usage * 100, 100), 0)
            }
        }

        return nil
    }
}
```

In `UsageAggregationTests.swift`, remove all `testCombine*` tests. Keep the new `testTokenPercentageFromSingleAccountQuota` test and add one more:

```swift
func testTokenPercentageReturnsNilWhenNoTokenLimit() {
    let quotaData = QuotaLimitData(
        limits: [
            QuotaLimit(
                type: "TIME_LIMIT",
                unit: 1,
                number: 1,
                usage: 100,
                currentValue: 50,
                remaining: 50,
                percentage: 50,
                nextResetTime: 1_710_000_000_000,
                usageDetails: nil
            )
        ],
        level: "pro"
    )

    XCTAssertNil(UsageAggregation.tokenPercentage(from: quotaData))
}
```

Keep the `makeUsage` and helper functions in the test file for potential future use, or remove if unused after deleting combine tests.

- [ ] **Step 4: Run tests**

Run: `cd ZaiUsageMenuBar && swift test --filter UsageAggregationTests`
Expected: All remaining tests PASS

- [ ] **Step 5: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageAggregation.swift ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/UsageAggregationTests.swift
git commit -m "refactor: remove combine methods from UsageAggregation, keep tokenPercentage"
```

---

### Task 3: Update UsageViewModel — remove aggregation, use per-account data

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageViewModel.swift`

- [ ] **Step 1: Rewrite UsageViewModel.swift**

```swift
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
```

Key changes:
- No more `combine()` call
- `UsageDashboardData` no longer has `combined` field
- Menu bar percentage comes from first successful account

- [ ] **Step 2: Build to verify compilation**

Run: `cd ZaiUsageMenuBar && swift build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageViewModel.swift
git commit -m "refactor: update UsageViewModel to use per-account data without aggregation"
```

---

### Task 4: Redesign MenuBarContentView — collapsible per-account sections

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`

- [ ] **Step 1: Rewrite the main content view and add AccountSectionView**

Replace the entire `MenuBarContentView.swift` content. The key changes:

1. Remove `CombinedUsageSectionView` and `AccountsUsageSectionView`
2. Add `AccountSectionView` with collapsible header
3. Add `@State private var expandedAccounts: Set<String>` to track expansion
4. Reuse existing `QuotaLimitsView`, `ModelUsageView`, `ToolUsageView` unchanged

New `MenuBarContentView`:

```swift
struct MenuBarContentView: View {
    @StateObject private var viewModel = UsageViewModel()
    @State private var showSettings = false
    @State private var expandedAccounts: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(lastUpdated: viewModel.dashboard?.lastUpdated, isLoading: viewModel.isLoading, showSettings: $showSettings, onRefresh: viewModel.refresh)

            ScrollView {
                VStack(spacing: 8) {
                    if let error = viewModel.error {
                        ErrorView(message: error, retryAction: viewModel.refresh)
                    }

                    if let dashboard = viewModel.dashboard {
                        ForEach(dashboard.accounts) { result in
                            AccountSectionView(
                                result: result,
                                isExpanded: expandedAccounts.contains(result.id),
                                onToggle: { toggleAccount(result.id) }
                            )
                        }
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(4)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
        }
        .frame(width: 300)
        .onAppear {
            viewModel.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshUsage)) { _ in
            viewModel.refresh()
        }
        .onChange(of: viewModel.dashboard?.accounts.first?.id) { _ in
            // Default expand all accounts when data loads
            if let accounts = viewModel.dashboard?.accounts {
                expandedAccounts = Set(accounts.map(\.id))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func toggleAccount(_ id: String) {
        if expandedAccounts.contains(id) {
            expandedAccounts.remove(id)
        } else {
            expandedAccounts.insert(id)
        }
    }
}
```

New `AccountSectionView`:

```swift
struct AccountSectionView: View {
    let result: AccountUsageResult
    let isExpanded: Bool
    let onToggle: () -> Void

    private var tokenPercentage: Double? {
        UsageAggregation.tokenPercentage(from: result.usage?.quotaLimits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Collapsible header
            Button(action: onToggle) {
                HStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(result.account.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    if let tokenPercentage = tokenPercentage {
                        Text(String(format: "%.0f%%", tokenPercentage))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(progressColor(for: tokenPercentage))
                    }
                }
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                if let usage = result.usage {
                    if usage.quotaLimits.limits != nil && !(usage.quotaLimits.limits?.isEmpty ?? true) {
                        QuotaLimitsView(quotaData: usage.quotaLimits)
                    }

                    if usage.modelUsage.totalUsage != nil {
                        ModelUsageView(modelData: usage.modelUsage)
                    }

                    if usage.toolUsage.totalUsage != nil {
                        ToolUsageView(toolData: usage.toolUsage)
                    }
                } else if let error = result.error {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
        }
    }
}
```

Keep `HeaderView`, `ErrorView`, `QuotaLimitsView`, `QuotaLimitRow`, `ModelUsageView`, `ToolUsageView`, `formatTokenCount`, and `progressColor` unchanged.

- [ ] **Step 2: Build to verify compilation**

Run: `cd ZaiUsageMenuBar && swift build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift
git commit -m "feat: redesign UI with collapsible per-account sections replacing combined view"
```

---

### Task 5: Clean up Localization keys

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/Localization.swift`

- [ ] **Step 1: Remove unused keys**

Remove the `combined` and `accounts` keys from the translations dictionary in `Localization.swift`. These are no longer referenced by any view.

- [ ] **Step 2: Build to verify**

Run: `cd ZaiUsageMenuBar && swift build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/Localization.swift
git commit -m "chore: remove unused localization keys (combined, accounts)"
```

---

### Task 6: Run full test suite and verify

- [ ] **Step 1: Run all tests**

Run: `cd ZaiUsageMenuBar && swift test`
Expected: All tests pass

- [ ] **Step 2: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address test failures from multi-account UI redesign"
```
