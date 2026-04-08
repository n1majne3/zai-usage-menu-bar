# Native UI Redesign

## Goal

Redesign the menu bar app UI to use a native macOS visual style with Apple system colors, circular progress rings for account identification, and compact stat rows — replacing the current plain card layout.

## Visual Identity

- **Width:** 300px (unchanged)
- **Background:** macOS native dark window background (`Color(nsColor: .windowBackgroundColor)`)
- **Cards:** Subtle translucent backgrounds (`rgba(255,255,255,0.05)`), 10px corner radius, no gradient accent bars
- **Account identification:** Small circular progress ring next to account name showing token usage percentage
- **Typography:** Apple system font. Large bold stats (15pt, weight 700) with small muted labels (8pt)
- **Progress bars:** Horizontal bars tinted with account's assigned system color; danger overrides at thresholds (orange >= 70%, red >= 90%)

## Card Structure

### Expanded

```
▼ 主账号                 PRO    [ring 10%]
  Tokens (5h)            10K / 100K
  [========                            ]
  2h 30m 后重置

  Tokens (周)            50K / 500K     ← only if weekly data exists
  [========                            ]
  3d 12h 后重置

  ─────────────────────────────────────
  1,234          567           89.2K
  Model Calls    Tool Calls    Tokens

  Web Search ................ 234
  MCP Reads ................. 189       ← only if toolDetails non-empty
```

### Collapsed

```
▶ 工作账号                        [ring 75%]
```

- Both 5h and weekly quota bars shown when data exists (unit == 6 means weekly)
- Level badge (e.g. "PRO") moved from quota section header into the account header row
- Reset timer shown below each progress bar
- Stats row: 3 compact columns — large number, small label below
- Tool breakdown: label-value rows, only when toolDetails is non-empty
- Collapsed: chevron + name + mini ring only

### Progress Ring

- Shows 5h window token percentage (most actionable short-term metric)
- 5h limit identified by: `type == "TOKENS_LIMIT"` where `unit != 6` (or unit is nil)
- Falls back to weekly percentage (`unit == 6`) if no 5h data
- Drawn with SwiftUI `Circle` + `trim` stroke — small inline size (~24pt)
- Tinted with account's assigned system color (danger thresholds override)

## Header Bar

```
[ZAI Logo]  ZAI Usage               09:42  ↻  ⚙  ✕
```

- App icon: official ZAI logo from `https://z-cdn.chatglm.cn/z-ai/static/logo.svg` (download as asset)
- SF Symbol buttons for refresh, settings, quit — subtle low opacity

## Account Color Assignment

Fixed palette cycling through Apple system colors:

| Account # | Color     | Hex       |
|-----------|-----------|-----------|
| 1         | Blue      | #0a84ff   |
| 2         | Orange    | #ff9f0a   |
| 3         | Green     | #30d158   |
| 4         | Purple    | #5e5ce6   |
| 5         | Cyan      | #64d2ff   |
| 6         | Pink      | #ff375f   |

Ring, percentage text, and progress bar tint all use the account's assigned color.

Danger override: if percentage >= 70%, use system orange (#ff9f0a); >= 90%, use system red (#ff453a). This overrides the account color for progress bars and ring fill.

## Interactions

- Tap card header → toggle expand/collapse
- All accounts expanded by default
- On first load, expand all (current behavior)
- Refresh → reloads all accounts
- Loading: compact ProgressView below cards
- Error: per-account inline error in expanded view

## Changes Required

### MenuBarContentView.swift

- Remove gradient accent bars from `AccountSectionView`
- Add circular progress ring component to account header (replacing text percentage)
- Add `accountColor(for: Int)` helper returning system colors from the palette
- Add `ringPercentage(from: QuotaLimitData)` helper — returns 5h limit percentage, falls back to weekly
  - 5h limit = first `QuotaLimit` where `type == "TOKENS_LIMIT"` and `unit != 6`
  - Weekly = first where `unit == 6`
- Move level badge from `QuotaLimitsView` into account header row
- Remove `QuotaLimitsView` as a wrapping section — render `QuotaLimitRow`s directly inside `AccountSectionView`
- Restyle `QuotaLimitRow`: progress bars use account color tint
- Remove `ModelUsageView` and `ToolUsageView` as separate sections
- Add compact stats row: 3 columns (Model Calls / Tool Calls / Total Tokens) with large bold numbers
- Add tool breakdown rows below stats (only when toolDetails exist)
- Update card backgrounds to `rgba(255,255,255,0.05)`, 10px radius
- Update overall background to native window color

### Assets

- Download ZAI logo SVG from `https://z-cdn.chatglm.cn/z-ai/static/logo.svg`
- Add to asset catalog as the header app icon

### UsageViewModel.swift / UsageModels.swift

- No structural changes needed — existing data models provide all required fields

### Localization.swift

- No new keys needed — existing labels suffice

## Testing

- Verify circular ring renders correctly at 0%, 50%, 100%+ (capped display)
- Verify 5h ring percentage, weekly fallback when no 5h data
- Verify danger color override at 70% and 90% thresholds
- Verify both quota bars show when weekly data present, single bar when only 5h
- Verify collapsed/expanded toggle
- Verify multiple accounts get distinct system colors
- Verify level badge appears in account header when present
