import XCTest
@testable import ZaiUsageMenuBar

final class UsageAggregationTests: XCTestCase {
    func testTokenPercentageFromSingleAccountQuota() {
        let quotaData = QuotaLimitData(
            limits: [
                QuotaLimit(
                    type: "TOKENS_LIMIT",
                    unit: 1,
                    number: 1,
                    usage: 5000,
                    currentValue: 500,
                    remaining: 4500,
                    percentage: 10,
                    nextResetTime: 1_710_000_000_000,
                    usageDetails: nil
                )
            ],
            level: "pro"
        )

        let percentage = UsageAggregation.tokenPercentage(from: quotaData)
        XCTAssertEqual(percentage ?? -1, 10, accuracy: 0.001)
    }

    func testTokenPercentageReturnsNilWhenNoTokenLimit() {
        let quotaData = QuotaLimitData(
            limits: [
                QuotaLimit(
                    type: "TIME_LIMIT",
                    unit: 1,
                    number: 1,
                    usage: 100,
                    currentValue: 50,
                    remaining: 50,
                    percentage: 50,
                    nextResetTime: 1_710_000_000_000,
                    usageDetails: nil
                )
            ],
            level: "pro"
        )

        XCTAssertNil(UsageAggregation.tokenPercentage(from: quotaData))
    }

    func testTokenPercentageCalculatedFromCurrentAndUsage() {
        let quotaData = QuotaLimitData(
            limits: [
                QuotaLimit(
                    type: "TOKENS_LIMIT",
                    unit: 1,
                    number: 1,
                    usage: 1000,
                    currentValue: 250,
                    remaining: 750,
                    percentage: nil,
                    nextResetTime: 1_710_000_000_000,
                    usageDetails: nil
                )
            ],
            level: "pro"
        )

        let percentage = UsageAggregation.tokenPercentage(from: quotaData)
        XCTAssertEqual(percentage ?? -1, 25, accuracy: 0.001)
    }

    func testTokenPercentageReturnsNilForNilInput() {
        XCTAssertNil(UsageAggregation.tokenPercentage(from: nil))
    }
}
