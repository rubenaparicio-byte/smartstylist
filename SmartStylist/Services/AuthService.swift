import AuthenticationServices
import Foundation
import Observation
import Security
import SwiftUI

// ── Keychain ──────────────────────────────────────────────────────────────────
// Wraps Security.framework for safe, non-exportable storage on this device only.

private enum KeychainHelper {
    private static let service = Bundle.main.bundleIdentifier ?? "com.smartstylist.app"

    static func save(_ value: String, account: String) {
        let data = Data(value.utf8)
        var query: [CFString: Any] = [
            kSecClass:          kSecClassGenericPassword,
            kSecAttrService:    service,
            kSecAttrAccount:    account,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        query[kSecValueData] = data
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  kCFBooleanTrue as Any,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var item: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// ── AuthService ───────────────────────────────────────────────────────────────

private let kAppleUserID = "appleUserID"

@MainActor
@Observable
final class AuthService {
    private(set) var isAuthenticated: Bool
    var loginError: String?

    init() {
        isAuthenticated = KeychainHelper.load(account: kAppleUserID) != nil
    }

    // Called from SignInWithAppleButton onCompletion on success.
    func handleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        KeychainHelper.save(credential.user, account: kAppleUserID)
        loginError = nil
        withAnimation(.dsSpring) { isAuthenticated = true }
    }

    // Called from SignInWithAppleButton onCompletion on failure.
    func handleError(_ error: Error) {
        let code = (error as? ASAuthorizationError)?.code
        guard code != .canceled else { return }
        loginError = "Sign-in failed. Please try again."
    }

    func signOut() {
        KeychainHelper.delete(account: kAppleUserID)
        withAnimation(.dsDefault) { isAuthenticated = false }
    }

    // Validates the stored Apple credential against Apple's servers on each
    // cold launch. Revoked or missing credentials trigger sign-out.
    func validateAppleCredential() async {
        guard let userID = KeychainHelper.load(account: kAppleUserID) else {
            isAuthenticated = false
            return
        }
        let state = await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider()
                .getCredentialState(forUserID: userID) { state, _ in
                    continuation.resume(returning: state)
                }
        }
        if state == .revoked || state == .notFound {
            signOut()
        }
    }
}
