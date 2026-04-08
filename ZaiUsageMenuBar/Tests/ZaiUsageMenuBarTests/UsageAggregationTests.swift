import XCTest
@testable import ZaiUsageMenuBar

final class UsageAggregationTests: XCTestCase {
    func testCombineUsageSumsModelTotalsAcrossAccounts() {
        let usageA = makeUsage(tokens: 100, calls: 2, currentValue: 20, usageLimit: 100)
        let usageB = makeUsage(tokens: 200, calls: 3, currentValue: 30, usageLimit: 150)

        let combined = UsageAggregation.combine([usageA, usageB])

        XCTAssertEqual(combined.modelUsage?.totalUsage?.totalTokensUsage, 300)
        XCTAssertEqual(combined.modelUsage?.totalUsage?.totalModelCallCount, 5)
    }

    func testCombineUsageMergesToolDetailsByModelName() {
        let usageA = makeUsage(
            tokens: 100,
            calls: 2,
            currentValue: 20,
            usageLimit: 100,
            toolDetails: [
                ToolDetail(modelName: "glm-4.5", totalUsageCount: 3),
                ToolDetail(modelName: "glm-4-air", totalUsageCount: 1)
            ]
        )
        let usageB = makeUsage(
            tokens: 200,
            calls: 5,
            currentValue: 50,
            usageLimit: 200,
            toolDetails: [
                ToolDetail(modelName: "glm-4.5", totalUsageCount: 4)
            ]
        )

        let combined = UsageAggregation.combine([usageA, usageB])
        let merged = Dictionary(uniqueKeysWithValues: (combined.toolUsage?.totalUsage?.toolDetails ?? []).map { ($0.modelName ?? "", $0.totalUsageCount ?? 0) })

        XCTAssertEqual(merged["glm-4.5"], 7)
        XCTAssertEqual(merged["glm-4-air"], 1)
    }

    func testTokenPercentageUsesAggregatedTokenLimit() {
        let usageA = makeUsage(tokens: 100, calls: 2, currentValue: 20, usageLimit: 100)
        let usageB = makeUsage(tokens: 200, calls: 3, currentValue: 30, usageLimit: 100)

        let combined = UsageAggregation.combine([usageA, usageB])
        let percentage = UsageAggregation.tokenPercentage(from: combined.quotaLimits)

        XCTAssertEqual(percentage ?? -1, 25, accuracy: 0.001)
    }

    func testCombineUsagePreservesPercentageOnlyTokenLimitAcrossAccounts() {
        let usageA = makeUsage(
            tokens: 100,
            calls: 2,
            currentValue: 78,
            usageLimit: 100,
            tokenQuota: makeTokenQuota(percentage: 18, nextResetTime: 1_710_000_000_000),
            timeQuota: makeTimeQuota(currentValue: 78, usageLimit: 100)
        )
        let usageB = makeUsage(
            tokens: 200,
            calls: 3,
            currentValue: 78,
            usageLimit: 100,
            tokenQuota: makeTokenQuota(percentage: 18, nextResetTime: 1_710_000_000_000),
            timeQuota: makeTimeQuota(currentValue: 78, usageLimit: 100)
        )

        let combined = UsageAggregation.combine([usageA, usageB])
        let tokenLimit = try? XCTUnwrap(combined.quotaLimits?.limits?.first { $0.type == "TOKENS_LIMIT" })

        XCTAssertEqual(tokenLimit?.percentage ?? -1, 18, accuracy: 0.001)
        XCTAssertEqual(UsageAggregation.tokenPercentage(from: combined.quotaLimits) ?? -1, 18, accuracy: 0.001)
    }

    func testCombineUsageHidesMixedQuotaMetadata() {
        let usageA = makeUsage(tokens: 100, calls: 2, currentValue: 20, usageLimit: 100, unit: 1, number: 1, level: "pro")
        let usageB = makeUsage(tokens: 200, calls: 3, currentValue: 30, usageLimit: 100, unit: 2, number: 2, level: "free")

        let combined = UsageAggregation.combine([usageA, usageB])
        let tokenLimit = try? XCTUnwrap(combined.quotaLimits?.limits?.first { $0.type == "TOKENS_LIMIT" })

        XCTAssertNil(tokenLimit?.unit)
        XCTAssertNil(tokenLimit?.number)
        XCTAssertNil(combined.quotaLimits?.level)
    }

    private func makeUsage(
        tokens: Int,
        calls: Int,
        currentValue: Double,
        usageLimit: Double,
        toolDetails: [ToolDetail] = [],
        unit: Int = 1,
        number: Int = 1,
        level: String = "pro",
        tokenQuota: QuotaLimit? = nil,
        timeQuota: QuotaLimit? = nil
    ) -> UsageData {
        let model = ModelUsageData(
            xTime: nil,
            modelCallCount: nil,
            tokensUsage: nil,
            totalUsage: ModelUsageTotal(totalModelCallCount: calls, totalTokensUsage: tokens)
        )

        let tool = ToolUsageData(
            xTime: nil,
            totalUsage: ToolUsageTotal(
                totalNetworkSearchCount: 1,
                totalWebReadMcpCount: 2,
                totalZreadMcpCount: 3,
                totalSearchMcpCount: 4,
                toolDetails: toolDetails
            )
        )

        let quota = QuotaLimitData(
            limits: [
                tokenQuota ?? QuotaLimit(
                    type: "TOKENS_LIMIT",
                    unit: unit,
                    number: number,
                    usage: usageLimit,
                    currentValue: currentValue,
                    remaining: usageLimit - currentValue,
                    percentage: currentValue / usageLimit * 100,
                    nextResetTime: 1_710_000_000_000,
                    usageDetails: nil
                ),
                timeQuota
            ].compactMap { $0 },
            level: level
        )

        return UsageData(modelUsage: model, toolUsage: tool, quotaLimits: quota, lastUpdated: Date())
    }

    private func makeTokenQuota(percentage: Double, nextResetTime: TimeInterval) -> QuotaLimit {
        QuotaLimit(
            type: "TOKENS_LIMIT",
            unit: 3,
            number: 5,
            usage: nil,
            currentValue: nil,
            remaining: nil,
            percentage: percentage,
            nextResetTime: nextResetTime,
            usageDetails: nil
        )
    }

    private func makeTimeQuota(currentValue: Double, usageLimit: Double) -> QuotaLimit {
        QuotaLimit(
            type: "TIME_LIMIT",
            unit: 5,
            number: 1,
            usage: usageLimit,
            currentValue: currentValue,
            remaining: usageLimit - currentValue,
            percentage: currentValue / usageLimit * 100,
            nextResetTime: 1_710_000_000_000,
            usageDetails: nil
        )
    }
}
