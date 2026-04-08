import Foundation

struct APIResponse<T: Codable>: Codable {
    let code: Int
    let msg: String
    let data: T
    let success: Bool
}

struct ModelUsageTotal: Codable {
    let totalModelCallCount: Int?
    let totalTokensUsage: Int?
}

struct ModelDataItem: Codable {
    let modelName: String?
    let sortOrder: Int?
    let tokensUsage: [Int?]?
    let totalTokens: Int?
}

struct ModelSummaryItem: Codable {
    let modelName: String?
    let totalTokens: Int?
    let sortOrder: Int?
}

struct ModelUsageData: Codable {
    let xTime: [String]?
    let modelCallCount: [Int?]?
    let tokensUsage: [Int?]?
    let totalUsage: ModelUsageTotal?
    let modelDataList: [ModelDataItem]?
    let modelSummaryList: [ModelSummaryItem]?
    let granularity: String?

    enum CodingKeys: String, CodingKey {
        case xTime = "x_time"
        case modelCallCount
        case tokensUsage
        case totalUsage
        case modelDataList
        case modelSummaryList
        case granularity
    }
}

struct ToolUsageData: Codable {
    let xTime: [String]?
    let totalUsage: ToolUsageTotal?
    
    enum CodingKeys: String, CodingKey {
        case xTime = "x_time"
        case totalUsage
    }
}

struct ToolUsageTotal: Codable {
    let totalNetworkSearchCount: Int?
    let totalWebReadMcpCount: Int?
    let totalZreadMcpCount: Int?
    let totalSearchMcpCount: Int?
    let toolDetails: [ToolDetail]?
}

struct ToolDetail: Codable, Hashable {
    let modelName: String?
    let totalUsageCount: Int?
}

struct QuotaLimitData: Codable {
    let limits: [QuotaLimit]?
    let level: String?
}

struct QuotaLimit: Codable {
    let type: String?
    let unit: Int?
    let number: Int?
    let usage: Double?
    let currentValue: Double?
    let remaining: Double?
    let percentage: Double?
    let nextResetTime: TimeInterval?
    let usageDetails: [UsageDetail]?
}

struct UsageDetail: Codable {
    let modelCode: String?
    let usage: Double?
}

struct AccountConfig: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var authToken: String
    var isEnabled: Bool

    var displayName: String {
        name.trimmed.isEmpty ? L10n.localized("unnamed_account") : name
    }
    
    static func newDefault() -> AccountConfig {
        AccountConfig(
            id: UUID().uuidString,
            name: L10n.localized("default_account_name"),
            authToken: "",
            isEnabled: true
        )
    }
}

enum HourlyRange {
    case today(referenceDate: Date)
    case last24h

    var isToday: Bool {
        if case .today = self { return true }
        return false
    }
}

struct HourlyBar {
    let label: String
    let segments: [(model: String, tokens: Int)]
    var totalTokens: Int { segments.reduce(0) { $0 + $1.tokens } }
}

enum HourlyBars {
    static func from(modelData: ModelUsageData, range: HourlyRange) -> [HourlyBar] {
        guard let xTime = modelData.xTime, !xTime.isEmpty,
              let modelItems = modelData.modelDataList else {
            return []
        }

        let calendar = Calendar.current
        let referenceDate: Date
        switch range {
        case .today(let ref): referenceDate = ref
        case .last24h: referenceDate = Date()
        }

        let todayStart = calendar.startOfDay(for: referenceDate)

        var bars: [HourlyBar] = []
        for (index, timeString) in xTime.enumerated() {
            guard let hourDate = parseHourDate(timeString) else { continue }

            if case .today = range {
                if hourDate < todayStart { continue }
            }

            var segments: [(model: String, tokens: Int)] = []
            for item in modelItems {
                guard let tokens = item.tokensUsage,
                      index < tokens.count,
                      let tokenCount = tokens[index], tokenCount > 0 else { continue }
                segments.append((model: item.modelName ?? "Unknown", tokens: tokenCount))
            }

            let total = segments.reduce(0) { $0 + $1.tokens }
            guard total > 0 else { continue }

            let label = formatHourLabel(hourDate: hourDate)
            bars.append(HourlyBar(label: label, segments: segments))
        }

        return bars
    }

    private static func parseHourDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    private static func formatHourLabel(hourDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: hourDate)
    }
}

struct AccountUsageResult: Identifiable {
    var id: String { account.id }
    let account: AccountConfig
    let usage: UsageData?
    let error: String?
}

struct UsageDashboardData {
    let accounts: [AccountUsageResult]
    let lastUpdated: Date
}
