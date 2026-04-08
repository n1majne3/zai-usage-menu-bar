import Foundation

class UsageAPIClient {
    static let shared = UsageAPIClient()

    static let baseUrlOptions = [
        "https://api.z.ai/api/anthropic",
        "https://open.bigmodel.cn/api/anthropic"
    ]

    private var selectedBaseUrl: String {
        UserDefaults.standard.string(forKey: "selectedBaseUrl")
        ?? Self.baseUrlOptions[1]
    }

    private var monitorBase: String {
        selectedBaseUrl.replacingOccurrences(of: "/anthropic", with: "")
    }

    private var modelUsageUrl: String { "\(monitorBase)/monitor/usage/model-usage" }
    private var toolUsageUrl: String { "\(monitorBase)/monitor/usage/tool-usage" }
    private var quotaLimitUrl: String { "\(monitorBase)/monitor/usage/quota/limit" }
    
    private init() {}
    
    func fetchUsage(for account: AccountConfig) async throws -> UsageData {
        let authToken = account.authToken.trimmed
        guard !authToken.isEmpty else {
            throw UsageError.missingAuthToken
        }
        
        let now = Date()
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) else {
            throw UsageError.invalidDate
        }
        let endDate = now
        
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour], from: endDate)
        
        let startTime = String(format: "%04d-%02d-%02d %02d:00:00",
                               startComponents.year!, startComponents.month!, startComponents.day!, startComponents.hour!)
        let endTime = String(format: "%04d-%02d-%02d %02d:59:59",
                             endComponents.year!, endComponents.month!, endComponents.day!, endComponents.hour!)
        
        async let modelUsageTask = fetchJSON(url: modelUsageUrl, startTime: startTime, endTime: endTime, authToken: authToken)
        async let toolUsageTask = fetchJSON(url: toolUsageUrl, startTime: startTime, endTime: endTime, authToken: authToken)
        async let quotaLimitTask = fetchJSON(url: quotaLimitUrl, startTime: nil, endTime: nil, authToken: authToken)
        
        let (modelUsageRaw, toolUsageRaw, quotaLimitRaw) = try await (modelUsageTask, toolUsageTask, quotaLimitTask)
        
        let modelUsageResponse: APIResponse<ModelUsageData>
        let toolUsageResponse: APIResponse<ToolUsageData>
        let quotaLimitResponse: APIResponse<QuotaLimitData>
        
        do {
            modelUsageResponse = try JSONDecoder().decode(APIResponse<ModelUsageData>.self, from: modelUsageRaw)
        } catch {
            throw UsageError.decodeError(endpoint: "model-usage", rawJSON: modelUsageRaw, underlying: error)
        }
        
        do {
            toolUsageResponse = try JSONDecoder().decode(APIResponse<ToolUsageData>.self, from: toolUsageRaw)
        } catch {
            throw UsageError.decodeError(endpoint: "tool-usage", rawJSON: toolUsageRaw, underlying: error)
        }
        
        do {
            quotaLimitResponse = try JSONDecoder().decode(APIResponse<QuotaLimitData>.self, from: quotaLimitRaw)
        } catch {
            throw UsageError.decodeError(endpoint: "quota-limit", rawJSON: quotaLimitRaw, underlying: error)
        }
        
        return UsageData(
            modelUsage: modelUsageResponse.data,
            toolUsage: toolUsageResponse.data,
            quotaLimits: quotaLimitResponse.data,
            lastUpdated: Date()
        )
    }
    
    func fetchAllUsage(accounts: [AccountConfig]) async -> [AccountUsageResult] {
        guard !accounts.isEmpty else { return [] }
        
        return await withTaskGroup(of: (Int, AccountUsageResult).self) { group in
            for (index, account) in accounts.enumerated() {
                group.addTask {
                    do {
                        let usage = try await self.fetchUsage(for: account)
                        return (index, AccountUsageResult(account: account, usage: usage, error: nil))
                    } catch {
                        return (index, AccountUsageResult(account: account, usage: nil, error: error.localizedDescription))
                    }
                }
            }
            
            var orderedResults = Array<AccountUsageResult?>(repeating: nil, count: accounts.count)
            for await (index, result) in group {
                orderedResults[index] = result
            }
            return orderedResults.compactMap { $0 }
        }
    }
    
    private func fetchJSON(url: String, startTime: String?, endTime: String?, authToken: String) async throws -> Data {
        guard var components = URLComponents(string: url) else {
            throw UsageError.invalidURL
        }
        
        if let startTime = startTime, let endTime = endTime {
            components.queryItems = [
                URLQueryItem(name: "startTime", value: startTime),
                URLQueryItem(name: "endTime", value: endTime)
            ]
        }
        
        guard let requestUrl = components.url else {
            throw UsageError.invalidURL
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("en-US,en", forHTTPHeaderField: "Accept-Language")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw UsageError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return data
    }
}

struct UsageData {
    let modelUsage: ModelUsageData
    let toolUsage: ToolUsageData
    let quotaLimits: QuotaLimitData
    let lastUpdated: Date
}

enum UsageError: Error, LocalizedError {
    case missingAuthToken
    case invalidURL
    case invalidResponse
    case invalidDate
    case httpError(statusCode: Int, data: Data)
    case decodeError(endpoint: String, rawJSON: Data, underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAuthToken:
            return "Missing authentication token. Please configure it in Settings."
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidDate:
            return "Invalid date calculation."
        case .httpError(let statusCode, let data):
            if let errorMessage = String(data: data, encoding: .utf8) {
                return "HTTP Error \(statusCode): \(errorMessage)"
            }
            return "HTTP Error \(statusCode)"
        case .decodeError(let endpoint, let rawJSON, let underlying):
            if let jsonString = String(data: rawJSON, encoding: .utf8) {
                return "Failed to decode \(endpoint) response: \(underlying.localizedDescription)\n\nRaw JSON:\n\(jsonString)"
            }
            return "Failed to decode \(endpoint) response: \(underlying.localizedDescription)"
        }
    }
}
