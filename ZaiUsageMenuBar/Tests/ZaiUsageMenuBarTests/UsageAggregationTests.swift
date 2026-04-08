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

extension UsageAggregationTests {
    func testRingPercentage5hPreferred() {
        let limit5h = QuotaLimit(
            type: "TOKENS_LIMIT", unit: nil, number: nil,
            usage: 100000, currentValue: 10000, remaining: nil,
            percentage: 10.0, nextResetTime: nil, usageDetails: nil
        )
        let limitWeekly = QuotaLimit(
            type: "TOKENS_LIMIT", unit: 6, number: nil,
            usage: 500000, currentValue: 50000, remaining: nil,
            percentage: 10.0, nextResetTime: nil, usageDetails: nil
        )
        let data = QuotaLimitData(limits: [limit5h, limitWeekly], level: nil)
        let result = UsageAggregation.ringPercentage(from: data)
        XCTAssertEqual(result, 10.0)
    }

    func testRingPercentageFallsBackToWeekly() {
        let limitWeekly = QuotaLimit(
            type: "TOKENS_LIMIT", unit: 6, number: nil,
            usage: 500000, currentValue: 50000, remaining: nil,
            percentage: 10.0, nextResetTime: nil, usageDetails: nil
        )
        let data = QuotaLimitData(limits: [limitWeekly], level: nil)
        let result = UsageAggregation.ringPercentage(from: data)
        XCTAssertEqual(result, 10.0)
    }

    func testRingPercentageNilWhenNoTokenLimits() {
        let data = QuotaLimitData(limits: [], level: nil)
        let result = UsageAggregation.ringPercentage(from: data)
        XCTAssertNil(result)
    }
}
