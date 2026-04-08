import XCTest
@testable import ZaiUsageMenuBar

final class AccountConfigStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AccountConfigStore.clearInMemoryTokenCache()
    }

    func testLoadAccountsMigratesLegacyTokenWhenAccountsMissing() {
        let defaults = makeDefaults()
        let tokenStore = InMemoryAuthTokenStore()
        defaults.set("legacy-token", forKey: "anthropicAuthToken")

        let accounts = AccountConfigStore.loadAccounts(userDefaults: defaults, tokenStore: tokenStore)

        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts.first?.authToken, "legacy-token")
        XCTAssertTrue(accounts.first?.isEnabled == true)
        XCTAssertEqual(tokenStore.authToken(for: accounts[0].id), "legacy-token")
    }

    func testSaveAccountsStoresTokensOutsideUserDefaults() throws {
        let defaults = makeDefaults()
        let tokenStore = InMemoryAuthTokenStore()
        let saved = [AccountConfig(id: "a1", name: "A", authToken: "token-a", isEnabled: true)]

        try AccountConfigStore.saveAccounts(saved, userDefaults: defaults, tokenStore: tokenStore)
        let rawData = try XCTUnwrap(defaults.data(forKey: AccountConfigStore.accountsKey))
        let rawString = try XCTUnwrap(String(data: rawData, encoding: .utf8))
        let accounts = AccountConfigStore.loadAccounts(userDefaults: defaults, tokenStore: tokenStore)

        XCTAssertFalse(rawString.contains("token-a"))
        XCTAssertEqual(tokenStore.authToken(for: "a1"), "token-a")
        XCTAssertEqual(accounts, saved)
    }

    func testLoadAccountsCachesAuthTokensBetweenRefreshes() throws {
        let defaults = makeDefaults()
        let tokenStore = CountingAuthTokenStore(tokens: ["a1": "token-a"])
        let stored = [StoredAccountConfig(id: "a1", name: "A", isEnabled: true)]
        defaults.set(try JSONEncoder().encode(stored), forKey: AccountConfigStore.accountsKey)

        _ = AccountConfigStore.loadAccounts(userDefaults: defaults, tokenStore: tokenStore)
        _ = AccountConfigStore.loadAccounts(userDefaults: defaults, tokenStore: tokenStore)

        XCTAssertEqual(tokenStore.readCount, 1)
    }

    private func makeDefaults(file: StaticString = #filePath, line: UInt = #line) -> UserDefaults {
        let name = "test.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else {
            XCTFail("Could not create UserDefaults suite", file: file, line: line)
            return .standard
        }
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

private final class InMemoryAuthTokenStore: AuthTokenStore {
    private var tokens: [String: String] = [:]

    func authToken(for accountID: String) -> String? {
        tokens[accountID]
    }

    func setAuthToken(_ token: String, for accountID: String) throws {
        tokens[accountID] = token
    }

    func removeAuthToken(for accountID: String) throws {
        tokens.removeValue(forKey: accountID)
    }
}

private final class CountingAuthTokenStore: AuthTokenStore {
    private var tokens: [String: String]
    private(set) var readCount = 0

    init(tokens: [String: String]) {
        self.tokens = tokens
    }

    func authToken(for accountID: String) -> String? {
        readCount += 1
        return tokens[accountID]
    }

    func setAuthToken(_ token: String, for accountID: String) throws {
        tokens[accountID] = token
    }

    func removeAuthToken(for accountID: String) throws {
        tokens.removeValue(forKey: accountID)
    }
}

private struct StoredAccountConfig: Codable {
    let id: String
    let name: String
    let isEnabled: Bool
}
