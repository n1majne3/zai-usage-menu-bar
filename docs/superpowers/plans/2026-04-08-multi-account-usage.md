# Multi-Account Usage Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement multi-account API support with combined totals and per-account breakdown in the menu bar popover.

**Architecture:** Add an account store (`accountsV1`) with legacy-token migration, fetch enabled accounts concurrently, aggregate successful payloads into combined usage, and render both combined and per-account cards in UI. Keep failures isolated at account level so one failure does not block others.

**Tech Stack:** Swift 5.9, SwiftUI, Foundation, XCTest, Swift Package Manager.

---

### Task 1: Add Test Target and RED Tests for Core Logic

**Files:**
- Modify: `ZaiUsageMenuBar/Package.swift`
- Create: `ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/AccountConfigStoreTests.swift`
- Create: `ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/UsageAggregationTests.swift`

- [ ] **Step 1: Add test target**

```swift
// In Package.swift targets:
.testTarget(
    name: "ZaiUsageMenuBarTests",
    dependencies: ["ZaiUsageMenuBar"],
    path: "Tests/ZaiUsageMenuBarTests"
)
```

- [ ] **Step 2: Write failing migration test**

```swift
func testLoadAccountsMigratesLegacyTokenWhenAccountsMissing() throws {
    let defaults = makeDefaults()
    defaults.set("legacy-token", forKey: AccountConfigStore.legacyTokenKey)
    let accounts = AccountConfigStore.loadAccounts(userDefaults: defaults)
    XCTAssertEqual(accounts.count, 1)
    XCTAssertEqual(accounts.first?.authToken, "legacy-token")
}
```

- [ ] **Step 3: Write failing aggregation tests**

```swift
func testCombineUsageSumsTotalsAcrossAccounts() {
    let combined = UsageAggregation.combine([makeUsage(tokens: 100, calls: 2), makeUsage(tokens: 200, calls: 3)])
    XCTAssertEqual(combined.modelUsage?.totalUsage?.totalTokensUsage, 300)
    XCTAssertEqual(combined.modelUsage?.totalUsage?.totalModelCallCount, 5)
}
```

- [ ] **Step 4: Run tests and verify RED**

Run: `cd ZaiUsageMenuBar && swift test`  
Expected: FAIL because `AccountConfigStore`/`UsageAggregation` are not implemented yet.

- [ ] **Step 5: Commit**

```bash
git add ZaiUsageMenuBar/Package.swift ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/AccountConfigStoreTests.swift ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/UsageAggregationTests.swift
git commit -m "test: add failing tests for account migration and usage aggregation"
```

### Task 2: Implement Account Store and Aggregator (GREEN)

**Files:**
- Create: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/AccountConfigStore.swift`
- Create: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageAggregation.swift`
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageModels.swift`
- Test: `ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/AccountConfigStoreTests.swift`
- Test: `ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/UsageAggregationTests.swift`

- [ ] **Step 1: Add account and dashboard models**

```swift
struct AccountConfig: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var authToken: String
    var isEnabled: Bool
}

struct AccountUsageResult: Identifiable {
    var id: String { account.id }
    let account: AccountConfig
    let usage: UsageData?
    let error: String?
}
```

- [ ] **Step 2: Implement store with migration**

```swift
enum AccountConfigStore {
    static let accountsKey = "accountsV1"
    static let legacyTokenKey = "anthropicAuthToken"
    static func loadAccounts(userDefaults: UserDefaults = .standard) -> [AccountConfig] { ... }
    static func saveAccounts(_ accounts: [AccountConfig], userDefaults: UserDefaults = .standard) throws { ... }
}
```

- [ ] **Step 3: Implement combined aggregation helpers**

```swift
enum UsageAggregation {
    static func combine(_ usages: [UsageData]) -> CombinedUsageData { ... }
    static func tokenPercentage(from quotaLimits: QuotaLimitData?) -> Double? { ... }
}
```

- [ ] **Step 4: Run tests and verify GREEN**

Run: `cd ZaiUsageMenuBar && swift test`  
Expected: PASS for migration and aggregation tests.

- [ ] **Step 5: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageModels.swift ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/AccountConfigStore.swift ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageAggregation.swift
git commit -m "feat: add account store and usage aggregation logic"
```

### Task 3: Implement Multi-Account API Fetching

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageAPIClient.swift`
- Test: `ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/UsageAggregationTests.swift`

- [ ] **Step 1: Add per-account fetch method**

```swift
func fetchUsage(for account: AccountConfig) async throws -> UsageData
```

- [ ] **Step 2: Add concurrent bulk fetch**

```swift
func fetchAllUsage(accounts: [AccountConfig]) async -> [AccountUsageResult] {
    await withTaskGroup(of: (Int, AccountUsageResult).self) { group in ... }
}
```

- [ ] **Step 3: Keep ordering stable and failure isolated**

```swift
AccountUsageResult(account: account, usage: nil, error: error.localizedDescription)
```

- [ ] **Step 4: Run tests/build**

Run: `cd ZaiUsageMenuBar && swift test && swift build`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageAPIClient.swift
git commit -m "feat: fetch account usage concurrently with partial failure support"
```

### Task 4: Update ViewModel for Dashboard State

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageViewModel.swift`
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/AppDelegate.swift`

- [ ] **Step 1: Replace single-account state with dashboard state**

```swift
@Published var dashboard: UsageDashboardData?
@Published var error: String?
```

- [ ] **Step 2: Implement refresh flow using account store + bulk fetch**

```swift
let accounts = AccountConfigStore.loadAccounts()
let enabled = accounts.filter { $0.isEnabled && !$0.authToken.trimmed.isEmpty }
let results = await UsageAPIClient.shared.fetchAllUsage(accounts: enabled)
```

- [ ] **Step 3: Aggregate successes and update status item**

```swift
let combined = UsageAggregation.combine(successes)
AppDelegate.shared?.updateStatusItem(percentage: UsageAggregation.tokenPercentage(from: combined.quotaLimits))
```

- [ ] **Step 4: Run tests/build**

Run: `cd ZaiUsageMenuBar && swift test && swift build`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageViewModel.swift ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/AppDelegate.swift
git commit -m "feat: use dashboard state with combined multi-account status"
```

### Task 5: Update Settings and Popover UI

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/SettingsView.swift`
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/Localization.swift`

- [ ] **Step 1: Replace single token form with account list editor**

```swift
@State private var accounts: [AccountConfig] = []
Button(L10n.localized("add_account")) { accounts.append(AccountConfig.newDefault()) }
```

- [ ] **Step 2: Save with validation**

```swift
guard validate(accounts) else { return }
try AccountConfigStore.saveAccounts(accounts)
NotificationCenter.default.post(name: .refreshUsage, object: nil)
```

- [ ] **Step 3: Render combined section + per-account section**

```swift
if let combined = viewModel.dashboard?.combined { ... }
AccountsUsageSection(results: viewModel.dashboard?.accounts ?? [])
```

- [ ] **Step 4: Add localization keys**

```swift
"combined", "accounts", "add_account", "account_name", "enabled", "delete", "default_account_name", "no_accounts_configured", "all_accounts_failed"
```

- [ ] **Step 5: Run tests/build**

Run: `cd ZaiUsageMenuBar && swift test && swift build`  
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/SettingsView.swift ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/Localization.swift
git commit -m "feat: add multi-account settings and combined account views"
```

### Task 6: Final Verification and Wrap-Up

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README configuration section**

```markdown
- Add multiple named accounts in Settings
- Combined menu bar percentage and per-account breakdown behavior
```

- [ ] **Step 2: Full verification**

Run: `cd ZaiUsageMenuBar && swift test && swift build && swift run --help`  
Expected: tests/build succeed and app remains runnable.

- [ ] **Step 3: Final commit**

```bash
git add README.md
git commit -m "docs: document multi-account configuration and behavior"
```
