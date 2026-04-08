import Foundation

enum UsageAggregation {
    static func combine(_ usages: [UsageData]) -> CombinedUsageData {
        guard !usages.isEmpty else {
            return CombinedUsageData(modelUsage: nil, toolUsage: nil, quotaLimits: nil)
        }
        
        return CombinedUsageData(
            modelUsage: combineModelUsage(usages),
            toolUsage: combineToolUsage(usages),
            quotaLimits: combineQuotaLimits(usages)
        )
    }
    
    static func tokenPercentage(from quotaLimits: QuotaLimitData?) -> Double? {
        let tokenLimit = quotaLimits?.limits?.first { $0.type == "TOKENS_LIMIT" }
        return percentage(for: tokenLimit)
    }
    
    private static func combineModelUsage(_ usages: [UsageData]) -> ModelUsageData {
        let totalTokens = usages.compactMap { $0.modelUsage.totalUsage?.totalTokensUsage }.reduce(0, +)
        let totalCalls = usages.compactMap { $0.modelUsage.totalUsage?.totalModelCallCount }.reduce(0, +)
        
        return ModelUsageData(
            xTime: nil,
            modelCallCount: nil,
            tokensUsage: nil,
            totalUsage: ModelUsageTotal(
                totalModelCallCount: totalCalls,
                totalTokensUsage: totalTokens
            )
        )
    }
    
    private static func combineToolUsage(_ usages: [UsageData]) -> ToolUsageData {
        var totalNetworkSearch = 0
        var totalWebRead = 0
        var totalZRead = 0
        var totalSearchMcp = 0
        var detailsByModel: [String: Int] = [:]
        
        for usage in usages {
            if let totals = usage.toolUsage.totalUsage {
                totalNetworkSearch += totals.totalNetworkSearchCount ?? 0
                totalWebRead += totals.totalWebReadMcpCount ?? 0
                totalZRead += totals.totalZreadMcpCount ?? 0
                totalSearchMcp += totals.totalSearchMcpCount ?? 0
                
                for detail in totals.toolDetails ?? [] {
                    guard let modelName = detail.modelName, !modelName.isEmpty else { continue }
                    detailsByModel[modelName, default: 0] += detail.totalUsageCount ?? 0
                }
            }
        }
        
        let mergedDetails = detailsByModel
            .keys
            .sorted()
            .map { ToolDetail(modelName: $0, totalUsageCount: detailsByModel[$0]) }
        
        return ToolUsageData(
            xTime: nil,
            totalUsage: ToolUsageTotal(
                totalNetworkSearchCount: totalNetworkSearch,
                totalWebReadMcpCount: totalWebRead,
                totalZreadMcpCount: totalZRead,
                totalSearchMcpCount: totalSearchMcp,
                toolDetails: mergedDetails
            )
        )
    }
    
    private static func combineQuotaLimits(_ usages: [UsageData]) -> QuotaLimitData {
        let allLimits = usages.flatMap { $0.quotaLimits.limits ?? [] }
        let grouped = Dictionary(grouping: allLimits, by: { $0.type ?? "" })
            .filter { !$0.key.isEmpty }

        let sortedTypes = grouped.keys.sorted { lhs, rhs in
            if lhs == "TOKENS_LIMIT" { return true }
            if rhs == "TOKENS_LIMIT" { return false }
            if lhs == "TIME_LIMIT" { return true }
            if rhs == "TIME_LIMIT" { return false }
            return lhs < rhs
        }

        let combinedLimits = sortedTypes.compactMap { type -> QuotaLimit? in
            guard let limits = grouped[type], !limits.isEmpty else { return nil }
            let summedUsage = limits.compactMap(\.usage).reduce(0, +)
            let summedCurrent = limits.compactMap(\.currentValue).reduce(0, +)
            let hasUsage = limits.contains { $0.usage != nil }
            let hasCurrent = limits.contains { $0.currentValue != nil }
            let usageValue = hasUsage ? summedUsage : nil
            let currentValue = hasCurrent ? summedCurrent : nil
            let explicitPercentages = limits.compactMap(\.percentage)
            let percentage: Double?
            if let usageValue, let currentValue, usageValue > 0 {
                percentage = currentValue / usageValue * 100
            } else if explicitPercentages.isEmpty {
                percentage = nil
            } else {
                percentage = explicitPercentages.reduce(0, +) / Double(explicitPercentages.count)
            }
            let earliestReset = limits.compactMap(\.nextResetTime).min()
            let remaining: Double?
            if let usageValue, let currentValue {
                remaining = max(usageValue - currentValue, 0)
            } else {
                remaining = nil
            }
            
            return QuotaLimit(
                type: type,
                unit: commonValue(in: limits.compactMap(\.unit)),
                number: commonValue(in: limits.compactMap(\.number)),
                usage: usageValue,
                currentValue: currentValue,
                remaining: remaining,
                percentage: percentage,
                nextResetTime: earliestReset,
                usageDetails: nil
            )
        }
        
        let level = commonValue(in: usages.compactMap { $0.quotaLimits.level })
        return QuotaLimitData(limits: combinedLimits, level: level)
    }
    
    private static func commonValue<T: Hashable>(in values: [T]) -> T? {
        let uniqueValues = Set(values)
        guard uniqueValues.count == 1 else { return nil }
        return uniqueValues.first
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
