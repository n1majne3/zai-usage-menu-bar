import Foundation

struct APIResponse<T: Codable>: Codable {
    let code: Int
    let msg: String
    let data: T
    let success: Bool
}

struct ModelUsageData: Codable {
    let xTime: [String]?
    let modelCallCount: [Int?]?
    let tokensUsage: [Int?]?
    let totalUsage: ModelUsageTotal?
    
    enum CodingKeys: String, CodingKey {
        case xTime = "x_time"
        case modelCallCount
        case tokensUsage
        case totalUsage
    }
}

struct ModelUsageTotal: Codable {
    let totalModelCallCount: Int?
    let totalTokensUsage: Int?
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
