import XCTest
@testable import ZaiUsageMenuBar

final class LocalizationTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "preferredLanguage")
        super.tearDown()
    }

    func testCloseKeyEnglish() {
        UserDefaults.standard.set("en", forKey: "preferredLanguage")
        XCTAssertEqual(L10n.localized("close"), "Close")
    }

    func testCloseKeyChinese() {
        UserDefaults.standard.set("zh-Hans", forKey: "preferredLanguage")
        XCTAssertEqual(L10n.localized("close"), "关闭")
    }
}
