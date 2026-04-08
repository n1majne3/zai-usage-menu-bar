# Multi-Account Usage Dashboard Design

Date: 2026-04-08
Project: `zai_usage_menu_bar`
Status: Proposed and user-approved in brainstorming session

## Goal

Add support for multiple ZhiPu API accounts and show:

- Combined totals across accounts
- Per-account breakdown in the same popover
- Partial results when some accounts fail

## Scope

In scope:

- Multi-account storage, editing, migration, fetching, aggregation, and display
- Combined menu bar percentage from all successful accounts
- Per-account success/error cards

Out of scope:

- Account grouping/tags
- Historical local persistence/caching
- New endpoint integrations

## Product Decisions

- Display mode: combined totals plus per-account breakdown
- Account identity: custom name + token per account
- Backward compatibility: auto-migrate existing `anthropicAuthToken` into `Default Account`
- Failure behavior: one failed account does not block others
- Menu bar percentage: combined token usage percentage across successful accounts

## Architecture

### Data Storage

Introduce `accountsV1` in `UserDefaults` as JSON-encoded array:

```swift
struct AccountConfig: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var authToken: String
    var isEnabled: Bool
}
```

Migration rule:

- If `accountsV1` is empty and legacy `anthropicAuthToken` exists and is non-empty:
  - Create one account with:
    - `id`: UUID string
    - `name`: `Default Account`
    - `authToken`: legacy token
    - `isEnabled`: `true`
  - Persist to `accountsV1`

### Runtime Models

```swift
struct AccountUsageResult: Identifiable {
    let account: AccountConfig
    let usage: UsageData?
    let error: String?
}

struct CombinedUsageData {
    let modelUsage: ModelUsageData?
    let toolUsage: ToolUsageData?
    let quotaLimits: QuotaLimitData?
}

struct UsageDashboardData {
    let combined: CombinedUsageData
    let accounts: [AccountUsageResult]
    let lastUpdated: Date
}
```

## Fetching Flow

1. Load and migrate account config if needed.
2. Filter enabled accounts with non-empty token.
3. If no valid enabled accounts exist, publish a settings-focused error state (no network calls).
4. Fetch each account using existing endpoints and auth header.
5. Perform concurrent account requests with task groups.
6. Store success or error per account; do not fail whole refresh on partial errors.
7. Aggregate successful account payloads into combined totals.
8. Publish dashboard state and update menu bar percentage from combined token limit.

## Aggregation Rules

Only successful accounts contribute to combined totals.

### Quota Limits

For each limit type (`TOKENS_LIMIT`, `TIME_LIMIT`):

- `currentValue`: sum of per-account `currentValue`
- `usage`: sum of per-account `usage`
- `percentage`: recompute from totals (`sumCurrent / sumUsage * 100`) when denominator > 0
- `nextResetTime`: earliest non-nil reset time among contributors

### Model Usage

- `totalModelCallCount`: sum
- `totalTokensUsage`: sum

### Tool Usage

- Sum top-level totals:
  - `totalNetworkSearchCount`
  - `totalWebReadMcpCount`
  - `totalZreadMcpCount`
  - `totalSearchMcpCount`
- Merge `toolDetails` by `modelName` and sum `totalUsageCount`

### Menu Bar

Status item title shows combined `TOKENS_LIMIT` percentage (rounded whole number).
If unavailable (no successful token quota data), show `--`.

## UI Design

### Settings

Replace single token field with account editor:

- Account rows with:
  - Name text field
  - Token secure field
  - Enabled toggle
  - Delete button
- Add account button
- Validation:
  - Name required after trimming
  - Enabled account must have non-empty token

### Popover

Order:

1. Header (existing controls)
2. Combined section (existing quota/model/tools cards fed by aggregated data)
3. Accounts section (one compact card per account):
  - Name
  - Success summary (token percent, tokens, calls), or
  - Per-account error message

Error handling:

- If all accounts fail, show global error and per-account error cards.
- If some accounts succeed, show combined data and failed account errors side by side.
- If no enabled account is configured, show a clear "configure accounts in settings" state.

## Implementation Plan (Code Areas)

- `UsageModels.swift`
  - Add account and dashboard runtime models
- `SettingsView.swift`
  - Account list management UI and persistence helpers
- `UsageAPIClient.swift`
  - Per-account fetch and concurrent multi-account fetch
  - Aggregation utility
- `UsageViewModel.swift`
  - Dashboard-driven state and refresh orchestration
- `MenuBarContentView.swift`
  - Combined + account breakdown rendering
- `Localization.swift`
  - New strings for account management and combined/account labels
- `AppDelegate.swift`
  - Keep status item update API; feed combined percentage from view model logic

## Testing Strategy

1. Migration
- Legacy token migrates into a single `Default Account` entry.

2. Aggregation
- Multiple successful accounts aggregate correctly for quota/model/tool totals.
- `toolDetails` merges by model name.

3. Partial failure
- One account failure does not block combined results from successful accounts.
- Failed account remains visible with explicit error.

4. UI smoke
- Add/edit/delete account works and persists.
- Popover shows combined section and per-account cards.

## Risks and Mitigations

- Risk: token leakage in logs or debug text
  - Mitigation: never print token; store and display masked/secure fields only.
- Risk: larger settings complexity
  - Mitigation: keep compact list UI and lightweight validation feedback.
- Risk: inconsistent combined percentages if payload fields are missing
  - Mitigation: aggregate defensively with nil-aware math and denominator checks.

## Acceptance Criteria

- User can add multiple accounts with custom names and tokens.
- Existing single-token users are automatically migrated.
- Popover shows combined usage and per-account breakdown together.
- Failed accounts show errors without hiding successful account data.
- Menu bar percentage reflects combined token usage.
