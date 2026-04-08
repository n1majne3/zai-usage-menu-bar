# Multi-Account UI Redesign

## Goal

Replace the current "Combined summary + minimal account cards" layout with per-account collapsible sections, each showing the full rich UI (配额, 模型用量, 工具调用). Remove the 汇总 section entirely.

## Current Behavior

- `CombinedUsageSectionView` aggregates all accounts into one 汇总 section with quota bars, model usage, and tool usage
- `AccountsUsageSectionView` renders minimal cards per account (name, percentage, 2-3 stats)
- `UsageAggregation` combines data from all accounts

## New Behavior

- Remove 汇总 section — no combined/aggregated view
- Each account renders the same rich detail: `QuotaLimitsView` + `ModelUsageView` + `ToolUsageView`
- Each account section is collapsible via a header tap
- Collapsed state shows: account name + token percentage
- Menu bar icon percentage comes from the first (or only) account's token usage

## UI Structure

```
Header (title, refresh, settings, quit)
ScrollView
  For each account (expanded):
    ▼ 账号 A                    10%
      [QuotaLimitsView] — quota bars with progress
      [ModelUsageView]  — token count + call count
      [ToolUsageView]   — tool calls breakdown
  For each account (collapsed):
    ▶ 账号 B                    75%
```

## Changes

### MenuBarContentView.swift

- Remove `CombinedUsageSectionView` and `AccountsUsageSectionView`
- Add `AccountSectionView` that wraps `QuotaLimitsView` + `ModelUsageView` + `ToolUsageView` with a collapsible header
- Add `@State private var expandedAccounts: Set<String>` to track which accounts are expanded
- Default: all accounts expanded
- Remove the `.----.` ASCII art section (no longer relevant)

### UsageViewModel.swift

- Remove `UsageAggregation.combine()` call — no longer need combined data
- `dashboard` model changes to just hold per-account results + last updated
- Menu bar percentage: use first successful account's token percentage instead of combined

### UsageModels.swift

- Remove `CombinedUsageData` struct
- Remove `UsageDashboardData` or simplify to not require `combined`
- Keep `AccountUsageResult` as-is

### UsageAggregation.swift

- Remove `combine()` and all `combine*` helper methods
- Keep `tokenPercentage(from:)` since it's still useful per-account

### Localization.swift

- Remove `combined` key (no longer used)
- Remove `accounts` key (replaced by per-account headers)
- Add `account_collapsed_hint` or similar if needed (probably not — the header already shows name + %)

### Tests (UsageAggregationTests.swift)

- Remove tests for `combine()` and related methods
- Keep/add test for `tokenPercentage(from:)` per-account usage

## Menu Bar Status Item

Currently shows combined token percentage. Change to show the first successful account's token percentage. If multiple accounts, could show the highest percentage (most concerning) — but start simple with first account.

## Error Handling

- Per-account errors shown inline when that account's section is expanded
- If all accounts fail, show error message as before
