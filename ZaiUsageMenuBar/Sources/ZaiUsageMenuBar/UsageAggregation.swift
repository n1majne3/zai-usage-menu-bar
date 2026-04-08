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
