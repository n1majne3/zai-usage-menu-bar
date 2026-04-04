import SwiftUI
import Foundation

@MainActor
class UsageViewModel: ObservableObject {
    @Published var modelUsage: ModelUsageData?
    @Published var toolUsage: ToolUsageData?
    @Published var quotaLimits: QuotaLimitData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?
    
    func refresh() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let usageData = try await UsageAPIClient.shared.fetchUsage()
                self.modelUsage = usageData.modelUsage
                self.toolUsage = usageData.toolUsage
                self.quotaLimits = usageData.quotaLimits
                self.lastUpdated = usageData.lastUpdated
                self.error = nil
                
                let tokenLimit = usageData.quotaLimits.limits?.first { $0.type == "TOKENS_LIMIT" }
                AppDelegate.shared?.updateStatusItem(percentage: tokenLimit?.percentage)
            } catch {
                self.error = error.localizedDescription
                AppDelegate.shared?.updateStatusItem(percentage: nil)
            }
            self.isLoading = false
        }
    }
}
