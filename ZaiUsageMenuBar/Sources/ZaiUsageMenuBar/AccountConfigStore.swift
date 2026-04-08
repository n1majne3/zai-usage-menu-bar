import Foundation
import Security

protocol AuthTokenStore {
    func authToken(for accountID: String) -> String?
    func setAuthToken(_ token: String, for accountID: String) throws
    func removeAuthToken(for accountID: String) throws
}

enum AccountConfigStore {
    static let accountsKey = "accountsV1"
    static let legacyTokenKey = "anthropicAuthToken"
    private static let tokenStore: AuthTokenStore = KeychainAuthTokenStore()
    private static let tokenCacheLock = NSLock()
    private static var tokenCache: [String: TokenCacheEntry] = [:]
    
    static func loadAccounts(
        userDefaults: UserDefaults = .standard,
        tokenStore: AuthTokenStore = tokenStore
    ) -> [AccountConfig] {
        if let data = userDefaults.data(forKey: accountsKey) {
            if let storedAccounts = try? JSONDecoder().decode([StoredAccountConfig].self, from: data) {
                return storedAccounts.map {
                    AccountConfig(
                        id: $0.id,
                        name: $0.name,
                        authToken: cachedAuthToken(for: $0.id, tokenStore: tokenStore) ?? "",
                        isEnabled: $0.isEnabled
                    )
                }
            }
            
            if let legacyAccounts = try? JSONDecoder().decode([AccountConfig].self, from: data) {
                try? saveAccounts(legacyAccounts, userDefaults: userDefaults, tokenStore: tokenStore)
                return legacyAccounts
            }
        }
        
        return migrateLegacyTokenIfNeeded(userDefaults: userDefaults, tokenStore: tokenStore)
    }
    
    static func saveAccounts(
        _ accounts: [AccountConfig],
        userDefaults: UserDefaults = .standard,
        tokenStore: AuthTokenStore = tokenStore
    ) throws {
        let existingIDs = accountIDs(in: userDefaults)
        let storedAccounts = accounts.map { StoredAccountConfig(id: $0.id, name: $0.name, isEnabled: $0.isEnabled) }
        let data = try JSONEncoder().encode(storedAccounts)
        userDefaults.set(data, forKey: accountsKey)
        userDefaults.removeObject(forKey: legacyTokenKey)
        
        for account in accounts {
            let trimmedToken = account.authToken.trimmed
            if trimmedToken.isEmpty {
                try tokenStore.removeAuthToken(for: account.id)
                cacheMissingToken(for: account.id)
            } else {
                try tokenStore.setAuthToken(trimmedToken, for: account.id)
                cacheToken(trimmedToken, for: account.id)
            }
        }
        
        let removedIDs = existingIDs.subtracting(accounts.map(\.id))
        for accountID in removedIDs {
            try tokenStore.removeAuthToken(for: accountID)
            removeCachedToken(for: accountID)
        }
    }
    
    private static func migrateLegacyTokenIfNeeded(
        userDefaults: UserDefaults,
        tokenStore: AuthTokenStore
    ) -> [AccountConfig] {
        let legacyToken = userDefaults.string(forKey: legacyTokenKey)?.trimmed ?? ""
        guard !legacyToken.isEmpty else { return [] }
        
        let account = AccountConfig(
            id: UUID().uuidString,
            name: L10n.localized("default_account_name"),
            authToken: legacyToken,
            isEnabled: true
        )
        
        try? saveAccounts([account], userDefaults: userDefaults, tokenStore: tokenStore)
        return [account]
    }
    
    private static func accountIDs(in userDefaults: UserDefaults) -> Set<String> {
        guard let data = userDefaults.data(forKey: accountsKey),
              let storedAccounts = try? JSONDecoder().decode([StoredAccountConfig].self, from: data)
        else {
            return []
        }
        
        return Set(storedAccounts.map(\.id))
    }

    static func clearInMemoryTokenCache() {
        tokenCacheLock.lock()
        defer { tokenCacheLock.unlock() }
        tokenCache.removeAll()
    }

    private static func cachedAuthToken(for accountID: String, tokenStore: AuthTokenStore) -> String? {
        tokenCacheLock.lock()
        if let cached = tokenCache[accountID] {
            tokenCacheLock.unlock()
            return cached.token
        }
        tokenCacheLock.unlock()

        let loadedToken = tokenStore.authToken(for: accountID)
        tokenCacheLock.lock()
        tokenCache[accountID] = loadedToken.map(TokenCacheEntry.present) ?? .missing
        tokenCacheLock.unlock()
        return loadedToken
    }

    private static func cacheToken(_ token: String, for accountID: String) {
        tokenCacheLock.lock()
        defer { tokenCacheLock.unlock() }
        tokenCache[accountID] = .present(token)
    }

    private static func cacheMissingToken(for accountID: String) {
        tokenCacheLock.lock()
        defer { tokenCacheLock.unlock() }
        tokenCache[accountID] = .missing
    }

    private static func removeCachedToken(for accountID: String) {
        tokenCacheLock.lock()
        defer { tokenCacheLock.unlock() }
        tokenCache.removeValue(forKey: accountID)
    }
}

private struct StoredAccountConfig: Codable {
    let id: String
    let name: String
    let isEnabled: Bool
}

private enum TokenCacheEntry {
    case present(String)
    case missing

    var token: String? {
        switch self {
        case .present(let token):
            return token
        case .missing:
            return nil
        }
    }
}

private struct KeychainAuthTokenStore: AuthTokenStore {
    private let service = "com.benjamin.zai-usage-menu-bar.auth-token"
    
    func authToken(for accountID: String) -> String? {
        var query = baseQuery(for: accountID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return token
    }

    func setAuthToken(_ token: String, for accountID: String) throws {
        let data = Data(token.utf8)
        let query = baseQuery(for: accountID)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus == errSecItemNotFound {
            var item: [String: Any] = baseQuery(for: accountID)
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw AccountConfigStoreError.keychainError(status: addStatus)
            }
            return
        }

        throw AccountConfigStoreError.keychainError(status: updateStatus)
    }
    
    func removeAuthToken(for accountID: String) throws {
        let status = SecItemDelete(baseQuery(for: accountID) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AccountConfigStoreError.keychainError(status: status)
        }
    }
    
    private func baseQuery(for accountID: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountID,
        ]
    }
}

enum AccountConfigStoreError: LocalizedError {
    case keychainError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            if let message = SecCopyErrorMessageString(status, nil) as String? {
                return message
            }
            return "Keychain error (\(status))."
        }
    }
}
