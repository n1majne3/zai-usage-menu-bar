# Hourly Token Usage Bar Chart

## Summary

Add a stacked bar chart to each account's expanded section in the menu bar popover, showing hourly token usage broken down by model. Supports toggling between "Today" and "24h" views.

## Data Layer

The `model-usage` API already returns `modelDataList` — an array of objects, each with a model name and a `tokensUsage` array aligned to the `x_time` hourly timestamps. Currently this field is not decoded.

**Changes:**

- Add `modelDataList` and `modelSummaryList` fields to `ModelUsageData`
- Define `ModelDataItem` codable struct with `modelName`, `sortOrder`, `tokensUsage`, `totalTokens`
- Define `ModelSummaryItem` codable struct with `modelName`, `totalTokens`, `sortOrder`
- Add a helper that filters `modelDataList` + `x_time` to the selected range (today from midnight, or last 24h from the API's natural range)
- Produce `[HourlyBar]` where each `HourlyBar` has a `label` (hour string like "09") and `segments: [(model: String, tokens: Int)]`

No new API calls.

## Time Range Toggle

A small segmented picker (`Today` / `24h`) rendered in the top-right corner of the chart area. Local `@State` in `AccountSectionView`. Defaults to "Today".

- **Today**: hours from midnight to current hour
- **24h**: full range returned by API (last ~24 hours of data)

## Chart View — `HourlyChartView`

A new SwiftUI view taking hourly bar data and the account accent color.

**Rendering:**

- For each hour with data, draw a vertical bar composed of stacked `RoundedRectangle` segments
- Stack bottom-up: first model at bottom, last on top
- Model colors drawn from the existing `accountColorPalette` (blue, orange, green, purple, cyan, pink), assigned by model sort order
- Bar height: ~60px total, width fills available space (card width minus padding)
- Each bar gets equal horizontal space with 2px gap between bars
- Zero-total hours are collapsed (skipped, not rendered as empty space)

**X-axis:**

- 4-5 time labels spread evenly below the bars
- Format: `HH` (e.g., "00", "06", "12", "18", "Now" for current hour)
- Only label hours that have corresponding bars

**Y-axis:**

- No explicit axis — the visual height ratio is sufficient for a compact popover chart
- Tooltip/hover not required for v1

## Legend

A compact single-line row below the chart bars, above the x-axis labels:
- Colored circle + model name for each model present in the current range
- Truncate model names if they overflow the available width
- Use 7-8pt font size

## Placement in UI

Inside `AccountSectionView`, rendered between `QuotaSectionView` and `StatsSectionView`, only when `modelDataList` is non-empty. Wrapped in a `VStack` with the same horizontal padding and dividers as the surrounding sections.

## File Changes

| File | Change |
|------|--------|
| `UsageModels.swift` | Add `ModelDataItem`, `ModelSummaryItem` structs; add `modelDataList`, `modelSummaryList`, `granularity` fields to `ModelUsageData` |
| `MenuBarContentView.swift` | Add `HourlyChartView`; integrate into `AccountSectionView` |
| `UsageModels.swift` | Add `HourlyBar` struct and filtering helper |

## Constraints

- Pure SwiftUI, no external dependencies or Charts framework
- Must fit within the 300px-wide popover
- Supports macOS 14+ (matches existing platform target)
- Must not degrade performance of existing refresh cycle
