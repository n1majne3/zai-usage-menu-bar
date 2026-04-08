# Native UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the menu bar app UI to use native macOS styling with Apple system colors, circular progress rings, and compact stat rows.

**Architecture:** The redesign is confined to `MenuBarContentView.swift` — all views are in this single file. We add a `TokenRingView` component, a color palette helper, restructure `AccountSectionView` to inline quota/stats/tools, and remove the separate `QuotaLimitsView`, `ModelUsageView`, `ToolUsageView` sections. A new helper in `UsageAggregation` extracts the 5h/weekly ring percentage. The ZAI logo SVG is downloaded as an asset.

**Tech Stack:** SwiftUI (macOS 14+), Swift 5.9

---

### Task 1: Add 5h Ring Percentage Helper

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageAggregation.swift`
- Test: `ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/UsageAggregationTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// In UsageAggregationTests.swift — add these tests to the existing file

extension UsageAggregationTests {
    func testRingPercentage5hPreferred() {
        let limit5h = QuotaLimit(
            type: "TOKENS_LIMIT", unit: nil, number: nil,
            usage: 100000, currentValue: 10000, remaining: nil,
            percentage: 10.0, nextResetTime: nil, usageDetails: nil
        )
        let limitWeekly = QuotaLimit(
            type: "TOKENS_LIMIT", unit: 6, number: nil,
            usage: 500000, currentValue: 50000, remaining: nil,
            percentage: 10.0, nextResetTime: nil, usageDetails: nil
        )
        let data = QuotaLimitData(limits: [limit5h, limitWeekly], level: nil)
        let result = UsageAggregation.ringPercentage(from: data)
        XCTAssertEqual(result, 10.0)
    }

    func testRingPercentageFallsBackToWeekly() {
        let limitWeekly = QuotaLimit(
            type: "TOKENS_LIMIT", unit: 6, number: nil,
            usage: 500000, currentValue: 50000, remaining: nil,
            percentage: 10.0, nextResetTime: nil, usageDetails: nil
        )
        let data = QuotaLimitData(limits: [limitWeekly], level: nil)
        let result = UsageAggregation.ringPercentage(from: data)
        XCTAssertEqual(result, 10.0)
    }

    func testRingPercentageNilWhenNoTokenLimits() {
        let data = QuotaLimitData(limits: [], level: nil)
        let result = UsageAggregation.ringPercentage(from: data)
        XCTAssertNil(result)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/benjamin/tools/zai_usage_menu_bar/ZaiUsageMenuBar && swift test --filter UsageAggregationTests 2>&1 | tail -20`
Expected: FAIL — `ringPercentage` method does not exist

- [ ] **Step 3: Write minimal implementation**

In `UsageAggregation.swift`, add this method after the existing `tokenPercentage(from:)`:

```swift
static func ringPercentage(from quotaLimits: QuotaLimitData?) -> Double? {
    guard let limits = quotaLimits?.limits else { return nil }
    // Prefer 5h window (TOKENS_LIMIT where unit != 6)
    let limit5h = limits.first { $0.type == "TOKENS_LIMIT" && $0.unit != 6 }
    if let limit5h { return percentage(for: limit5h) }
    // Fallback to weekly (unit == 6)
    let limitWeekly = limits.first { $0.type == "TOKENS_LIMIT" && $0.unit == 6 }
    return percentage(for: limitWeekly)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/benjamin/tools/zai_usage_menu_bar/ZaiUsageMenuBar && swift test --filter UsageAggregationTests 2>&1 | tail -20`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/UsageAggregation.swift ZaiUsageMenuBar/Tests/ZaiUsageMenuBarTests/UsageAggregationTests.swift
git commit -m "feat: add ringPercentage helper for 5h/weekly fallback"
```

---

### Task 2: Add Account Color Palette Helper

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`

This adds the color palette helper used by all subsequent tasks.

- [ ] **Step 1: Add the helper function**

At the bottom of `MenuBarContentView.swift`, replace the existing `progressColor(for:)` and `formatTokenCount` with:

```swift
private let accountColorPalette: [Color] = [
    Color(red: 10/255, green: 132/255, blue: 1),      // Blue #0a84ff
    Color(red: 255/255, green: 159/255, blue: 10/255), // Orange #ff9f0a
    Color(red: 48/255, green: 209/255, blue: 88/255),  // Green #30d158
    Color(red: 94/255, green: 92/255, blue: 230/255),  // Purple #5e5ce6
    Color(red: 100/255, green: 210/255, blue: 255/255),// Cyan #64d2ff
    Color(red: 255/255, green: 55/255, blue: 95/255),  // Pink #ff375f
]

func accountColor(for index: Int) -> Color {
    accountColorPalette[index % accountColorPalette.count]
}

func progressColor(for percentage: Double?, accountAccent: Color) -> Color {
    guard let percentage else { return accountAccent }
    if percentage >= 90 { return Color(red: 255/255, green: 69/255, blue: 58/255) }
    if percentage >= 70 { return Color(red: 255/255, green: 159/255, blue: 10/255) }
    return accountAccent
}

func formatTokenCount(_ count: Int) -> String {
    if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
    if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
    return "\(count)"
}
```

Note: the old `progressColor(for:) -> Color` (no accent parameter) is removed. All callers will be updated in later tasks.

- [ ] **Step 2: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift
git commit -m "feat: add Apple system color palette and account color helper"
```

---

### Task 3: Add TokenRingView Component

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`

- [ ] **Step 1: Add TokenRingView**

Add this struct in `MenuBarContentView.swift` before `AccountSectionView`:

```swift
struct TokenRingView: View {
    let percentage: Double
    let color: Color
    let size: CGFloat

    init(percentage: Double, color: Color, size: CGFloat = 24) {
        self.percentage = min(max(percentage, 0), 100)
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 2)
            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotation(.degrees(-90))
            Text(String(format: "%.0f", percentage))
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift
git commit -m "feat: add TokenRingView circular progress component"
```

---

### Task 4: Download and Add ZAI Logo Asset

**Files:**
- Create: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/Assets.xcassets/AppIcon.appiconset/` (already exists)
- Modify: Add logo image data

- [ ] **Step 1: Download the logo**

Run:
```bash
curl -sL "https://z-cdn.chatglm.cn/z-ai/static/logo.svg" -o /tmp/zai-logo.svg
```

Since SwiftUI cannot directly render SVGs from asset catalogs without Xcode's SVG support, and this is a Swift Package Manager project, we'll use an `AsyncImage` or convert to PNG. The simplest approach for a menu bar app is to load the logo from a remote URL at runtime using `AsyncImage` in the header.

- [ ] **Step 2: Update HeaderView to use AsyncImage for logo**

Replace the `HeaderView` with:

```swift
struct HeaderView: View {
    let lastUpdated: Date?
    let isLoading: Bool
    @Binding var showSettings: Bool
    var onRefresh: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            AsyncImage(url: URL(string: "https://z-cdn.chatglm.cn/z-ai/static/logo.svg")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Text("Z")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(5)
                }
            }
            .frame(width: 20, height: 20)

            Text(L10n.localized("app_title"))
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            }

            if let lastUpdated = lastUpdated {
                Text(lastUpdated, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button {
                onRefresh?()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help(L10n.localized("refresh"))

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help(L10n.localized("settings"))

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help(L10n.localized("quit"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
```

- [ ] **Step 3: Build to verify**

Run: `cd /Users/benjamin/tools/zai_usage_menu_bar/ZaiUsageMenuBar && swift build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift
git commit -m "feat: use ZAI logo in header via AsyncImage"
```

---

### Task 5: Redesign AccountSectionView (Header + Ring)

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`

This task replaces the `AccountSectionView` header to use `TokenRingView`, account colors, and the level badge. It also passes `colorIndex` down to sub-views.

- [ ] **Step 1: Rewrite AccountSectionView**

Replace the entire `AccountSectionView` struct with:

```swift
struct AccountSectionView: View {
    let result: AccountUsageResult
    let colorIndex: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    private var accentColor: Color { accountColor(for: colorIndex) }

    private var ringPercentageValue: Double? {
        UsageAggregation.ringPercentage(from: result.usage?.quotaLimits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(width: 10)

                    Text(result.account.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.85))

                    if let level = result.usage?.quotaLimits.level {
                        Text(level.uppercased())
                            .font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(3)
                    }

                    Spacer()

                    if let pct = ringPercentageValue {
                        TokenRingView(
                            percentage: pct,
                            color: progressColor(for: pct, accountAccent: accentColor),
                            size: 24
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    if let usage = result.usage {
                        if let limits = usage.quotaLimits.limits, !limits.isEmpty {
                            QuotaSectionView(quotaData: usage.quotaLimits, accentColor: accentColor)
                        }
                        if usage.modelUsage.totalUsage != nil || usage.toolUsage.totalUsage != nil {
                            StatsSectionView(usage: usage, accentColor: accentColor)
                        }
                    } else if let error = result.error {
                        Text(error)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                }
            }
        }
        .background(Color.primary.opacity(0.05))
        .cornerRadius(10)
    }
}
```

This won't compile yet — `QuotaSectionView` and `StatsSectionView` are added in the next tasks.

- [ ] **Step 2: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift
git commit -m "wip: redesign AccountSectionView header with ring and level badge"
```

---

### Task 6: Add QuotaSectionView (Inline Quota Bars)

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`

This replaces `QuotaLimitsView` and `QuotaLimitRow` with a simpler inline version that renders directly inside the account card.

- [ ] **Step 1: Add QuotaSectionView**

Remove the old `QuotaLimitsView` and `QuotaLimitRow` structs. Replace with:

```swift
struct QuotaSectionView: View {
    let quotaData: QuotaLimitData
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let limits = quotaData.limits, !limits.isEmpty {
                ForEach(Array(limits.enumerated()), id: \.offset) { _, limit in
                    QuotaBarRow(limit: limit, accentColor: accentColor)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

private struct QuotaBarRow: View {
    let limit: QuotaLimit
    let accentColor: Color

    private var label: String {
        if limit.type == "TOKENS_LIMIT" {
            return limit.unit == 6 ? L10n.localized("weekly_token_label") : L10n.localized("token_label")
        }
        if limit.type == "TIME_LIMIT" { return L10n.localized("mcp_label") }
        return limit.type ?? ""
    }

    private var resetDate: Date? {
        guard let t = limit.nextResetTime else { return nil }
        return Date(timeIntervalSince1970: t / 1000)
    }

    var body: some View {
        let color = progressColor(for: limit.percentage, accountAccent: accentColor)
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
                Spacer()
                if let current = limit.currentValue, let usage = limit.usage {
                    Text(String(format: "%.0f/%.0f", current, usage))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }

            if let pct = limit.percentage {
                ProgressView(value: min(pct, 100), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(height: 3)
            }

            if let resetDate = resetDate {
                HStack {
                    Spacer()
                    Text("\(L10n.localized("resets_prefix")) \(resetDate, style: .relative)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.4))
                }
            }
        }
        .padding(.bottom, 2)
    }
}
```

Note: The old `QuotaLimitsView` had a wrapping card with background/padding and a "Quota" section header. The new `QuotaSectionView` renders quota bars inline without a separate header — they live directly inside the account card.

- [ ] **Step 2: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift
git commit -m "feat: add QuotaSectionView with inline quota bars"
```

---

### Task 7: Add StatsSectionView (Compact Stats + Tool Breakdown)

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`

This replaces the separate `ModelUsageView` and `ToolUsageView` with a single compact stats section.

- [ ] **Step 1: Add StatsSectionView**

Remove the old `ModelUsageView` and `ToolUsageView` structs. Add:

```swift
struct StatsSectionView: View {
    let usage: UsageData
    let accentColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.primary.opacity(0.05))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)

            // Main stats row
            HStack(spacing: 0) {
                if let calls = usage.modelUsage.totalUsage?.totalModelCallCount {
                    StatColumn(value: "\(calls)", label: "Model Calls")
                    Spacer()
                }
                if let totalTools = usage.toolUsage.totalUsage?.totalSearchMcpCount {
                    StatColumn(value: "\(totalTools)", label: "Tool Calls")
                    Spacer()
                }
                if let tokens = usage.modelUsage.totalUsage?.totalTokensUsage {
                    StatColumn(value: formatTokenCount(tokens), label: "Tokens")
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)

            // Tool breakdown
            if let details = usage.toolUsage.totalUsage?.toolDetails, !details.isEmpty {
                VStack(spacing: 2) {
                    ForEach(details, id: \.self) { detail in
                        HStack {
                            Text(detail.modelName ?? "")
                                .font(.system(size: 9))
                                .foregroundColor(.primary.opacity(0.35))
                            Spacer()
                            Text("\(detail.totalUsageCount ?? 0)")
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .foregroundColor(.primary.opacity(0.45))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
    }
}

private struct StatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary.opacity(0.9))
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.primary.opacity(0.3))
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift
git commit -m "feat: add StatsSectionView with compact stats and tool breakdown"
```

---

### Task 8: Update MenuBarContentView to Pass colorIndex

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`

- [ ] **Step 1: Update the ForEach to pass colorIndex**

In `MenuBarContentView.body`, change the `ForEach` call:

From:
```swift
ForEach(dashboard.accounts) { result in
    AccountSectionView(
        result: result,
        isExpanded: expandedAccounts.contains(result.id),
        onToggle: { toggleAccount(result.id) }
    )
}
```

To:
```swift
ForEach(Array(dashboard.accounts.enumerated()), id: \.element.id) { index, result in
    AccountSectionView(
        result: result,
        colorIndex: index,
        isExpanded: expandedAccounts.contains(result.id),
        onToggle: { toggleAccount(result.id) }
    )
}
```

- [ ] **Step 2: Build and verify**

Run: `cd /Users/benjamin/tools/zai_usage_menu_bar/ZaiUsageMenuBar && swift build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

If there are compile errors from leftover references to old views (`QuotaLimitsView`, `ModelUsageView`, `ToolUsageView`, or the old `progressColor(for:)` signature), fix them now.

- [ ] **Step 3: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift
git commit -m "feat: wire up colorIndex to AccountSectionView"
```

---

### Task 9: Update Background to Native Window Color

**Files:**
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/MenuBarContentView.swift`
- Modify: `ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/AppDelegate.swift`

- [ ] **Step 1: Set native popover appearance**

In `AppDelegate.applicationDidFinishLaunching`, after `popover.behavior = .transient`, add:

```swift
popover.appearance = NSAppearance(named: .darkAqua)
```

This ensures the popover always uses dark mode styling matching the design.

- [ ] **Step 2: Commit**

```bash
git add ZaiUsageMenuBar/Sources/ZaiUsageMenuBar/AppDelegate.swift
git commit -m "feat: set popover to dark aqua appearance"
```

---

### Task 10: Final Build and Manual Testing

**Files:** None

- [ ] **Step 1: Full build**

Run: `cd /Users/benjamin/tools/zai_usage_menu_bar/ZaiUsageMenuBar && swift build -c release 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Run the app manually**

Run: `open /Users/benjamin/tools/zai_usage_menu_bar/ZaiUsageMenuBar/.build/arm64-apple-macosx/release/ZaiUsageMenuBar.app`

Manual checks:
- Click menu bar item — popover opens
- Account card shows with circular ring in header
- Level badge (PRO etc.) appears in header if present
- Both 5h and weekly quota bars show (if data has both)
- Stats row shows Model Calls, Tool Calls, Tokens in large bold
- Tool breakdown shows if toolDetails exist
- Click header to collapse/expand — ring stays visible when collapsed
- Multiple accounts have different system colors (blue, orange, green, etc.)
- Danger colors override at >=70% and >=90%
- Refresh button works
- Settings sheet opens
- ZAI logo loads in header (or fallback "Z" if offline)
