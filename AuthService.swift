import Foundation
import Security

/// Handles secure storage and retrieval of authentication tokens using Keychain.
/// This service isolates all Keychain logic, allowing the rest of the app to stay clean.
class AuthService {
    static let shared = AuthService()
    
    private let accessTokenKey = "com.homi.accessToken"
    private let refreshTokenKey = "com.homi.refreshToken"
    private let userIdKey = "com.homi.userId"
    
    private init() {}
    
    // MARK: - Token Storage
    
    /// Saves access token, optional refresh token, and optional user ID.
    /// Missing or empty values automatically clear their stored Keychain entries.
    func saveTokens(accessToken: String, refreshToken: String?, userId: String?) {
        saveToKeychain(key: accessTokenKey, value: accessToken)
        
        if let refreshToken, !refreshToken.isEmpty {
            saveToKeychain(key: refreshTokenKey, value: refreshToken)
        } else {
            deleteFromKeychain(key: refreshTokenKey)
        }
        
        if let userId, !userId.isEmpty {
            saveToKeychain(key: userIdKey, value: userId)
        } else {
            deleteFromKeychain(key: userIdKey)
        }
    }
    
    /// Returns the stored access token, if available.
    func getAccessToken() -> String? {
        return getFromKeychain(key: accessTokenKey)
    }
    
    /// Returns the stored refresh token, if available.
    func getRefreshToken() -> String? {
        return getFromKeychain(key: refreshTokenKey)
    }
    
    /// Returns the stored user ID, if available.
    func getUserId() -> String? {
        return getFromKeychain(key: userIdKey)
    }
    
    /// Removes all stored authentication values.
    func clearTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        deleteFromKeychain(key: userIdKey)
    }
    
    /// Basic authentication check based solely on presence of an access token.
    var isAuthenticated: Bool {
        return getAccessToken() != nil
    }
    
    // MARK: - Keychain Helpers
    
    /// Writes a string value to Keychain, replacing any existing item with the same key.
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Remove previous value to avoid duplicate entries
        SecItemDelete(query as CFDictionary)
        
        // Write new value
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Reads a string from Keychain.
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Removes a single Keychain entry.
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}