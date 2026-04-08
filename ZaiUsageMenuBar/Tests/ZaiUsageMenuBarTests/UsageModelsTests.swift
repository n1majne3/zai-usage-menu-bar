import XCTest
@testable import ZaiUsageMenuBar

final class UsageModelsTests: XCTestCase {
    func testDecodeModelDataList() throws {
        let json = """
        {
            "x_time": ["2026-04-09 10:00", "2026-04-09 11:00"],
            "modelCallCount": [5, 10],
            "tokensUsage": [1000, 2000],
            "totalUsage": {
                "totalModelCallCount": 15,
                "totalTokensUsage": 3000
            },
            "modelDataList": [
                {
                    "modelName": "GLM-5.1",
                    "sortOrder": 1,
                    "tokensUsage": [800, 1500],
                    "totalTokens": 2300
                },
                {
                    "modelName": "GLM-4.7",
                    "sortOrder": 2,
                    "tokensUsage": [200, 500],
                    "totalTokens": 700
                }
            ],
            "modelSummaryList": [
                {"modelName": "GLM-5.1", "totalTokens": 2300, "sortOrder": 1}
            ],
            "granularity": "hourly"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ModelUsageData.self, from: json)
        XCTAssertEqual(decoded.modelDataList?.count, 2)
        XCTAssertEqual(decoded.modelDataList?[0].modelName, "GLM-5.1")
        XCTAssertEqual(decoded.modelDataList?[0].tokensUsage, [800, 1500])
        XCTAssertEqual(decoded.modelSummaryList?.count, 1)
        XCTAssertEqual(decoded.granularity, "hourly")
    }
}

extension UsageModelsTests {
    func testHourlyBarFiltering24h() {
        let modelData = ModelUsageData(
            xTime: ["2026-04-08 22:00", "2026-04-08 23:00", "2026-04-09 00:00", "2026-04-09 01:00"],
            modelCallCount: [5, 0, 10, 3],
            tokensUsage: [1000, 0, 2000, 500],
            totalUsage: nil,
            modelDataList: [
                ModelDataItem(modelName: "GLM-5.1", sortOrder: 1, tokensUsage: [800, 0, 1500, 400], totalTokens: 2700),
                ModelDataItem(modelName: "GLM-4.7", sortOrder: 2, tokensUsage: [200, 0, 500, 100], totalTokens: 800)
            ],
            modelSummaryList: nil,
            granularity: "hourly"
        )

        let bars = HourlyBars.from(modelData: modelData, range: .last24h)
        // 24h: skip zero-total hours (23:00), keep 3 bars
        XCTAssertEqual(bars.count, 3)
        XCTAssertEqual(bars[0].label, "22")
        XCTAssertEqual(bars[0].totalTokens, 1000)
        XCTAssertEqual(bars[0].segments.count, 2)
        XCTAssertEqual(bars[0].segments[0].model, "GLM-5.1")
        XCTAssertEqual(bars[0].segments[0].tokens, 800)
        XCTAssertEqual(bars[0].segments[1].model, "GLM-4.7")
        XCTAssertEqual(bars[0].segments[1].tokens, 200)
    }

    func testHourlyBarFilteringToday() {
        let modelData = ModelUsageData(
            xTime: ["2026-04-08 23:00", "2026-04-09 00:00", "2026-04-09 01:00", "2026-04-09 02:00"],
            modelCallCount: [5, 10, 0, 3],
            tokensUsage: [1000, 2000, 0, 500],
            totalUsage: nil,
            modelDataList: [
                ModelDataItem(modelName: "GLM-5.1", sortOrder: 1, tokensUsage: [800, 1500, 0, 400], totalTokens: 2700)
            ],
            modelSummaryList: nil,
            granularity: "hourly"
        )

        let bars = HourlyBars.from(modelData: modelData, range: .today(referenceDate: date(year: 2026, month: 4, day: 9, hour: 2)))
        // Only Apr 9 hours: 00:00, 01:00, 02:00. Skip 01:00 (zero). Skip 23:00 (Apr 8).
        XCTAssertEqual(bars.count, 2)
        XCTAssertEqual(bars[0].label, "00")
        XCTAssertEqual(bars[1].label, "02")
    }

    func testHourlyBarEmptyModelData() {
        let modelData = ModelUsageData(
            xTime: nil,
            modelCallCount: nil,
            tokensUsage: nil,
            totalUsage: nil,
            modelDataList: nil,
            modelSummaryList: nil,
            granularity: nil
        )

        let bars = HourlyBars.from(modelData: modelData, range: .last24h)
        XCTAssertTrue(bars.isEmpty)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
