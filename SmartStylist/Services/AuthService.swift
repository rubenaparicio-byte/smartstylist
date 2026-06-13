import AuthenticationServices
import Foundation
import GoogleSignIn
import Observation
import Security
import SwiftUI
import UIKit

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

// ── KeychainStore ─────────────────────────────────────────────────────────────
// Closure-based wrapper around Keychain operations; injectable for testing.

struct KeychainStore {
    var save:   (_ value: String, _ account: String) -> Void
    var load:   (_ account: String) -> String?
    var delete: (_ account: String) -> Void

    static let live = KeychainStore(
        save:   { KeychainHelper.save($0, account: $1) },
        load:   { KeychainHelper.load(account: $0) },
        delete: { KeychainHelper.delete(account: $0) }
    )
}

// ── AuthService ───────────────────────────────────────────────────────────────

private let kAppleUserID  = "appleUserID"
private let kGoogleUserID = "googleUserID"

@MainActor
@Observable
final class AuthService {
    private(set) var isAuthenticated: Bool
    var loginError: String?
    private let keychain: KeychainStore

    init(keychain: KeychainStore = .live) {
        self.keychain = keychain
        isAuthenticated = keychain.load(kAppleUserID)  != nil
                       || keychain.load(kGoogleUserID) != nil
    }

    // ── Apple Sign-In ─────────────────────────────────────────────────────────

    func handleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        keychain.save(credential.user, kAppleUserID)
        loginError = nil
        withAnimation(.dsSpring) { isAuthenticated = true }
    }

    func handleError(_ error: Error) {
        let code = (error as? ASAuthorizationError)?.code
        guard code != .canceled else { return }
        loginError = "Sign-in failed. Please try again."
    }

    // Validates the stored Apple credential on cold launch.
    // Only signs out on .revoked — .notFound is a false positive in simulator/dev.
    // Skipped when the active session is Google-based.
    func validateAppleCredential() async {
        guard keychain.load(kGoogleUserID) == nil else { return }
        guard let userID = keychain.load(kAppleUserID) else {
            isAuthenticated = false
            return
        }
        let state = await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider()
                .getCredentialState(forUserID: userID) { state, _ in
                    continuation.resume(returning: state)
                }
        }
        if state == .revoked {
            signOut()
        }
    }

    // ── Google Sign-In ────────────────────────────────────────────────────────

    func signInWithGoogle() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            loginError = "Unable to present sign-in."
            return
        }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            let userID = result.user.userID ?? result.user.profile?.email ?? ""
            keychain.save(userID, kGoogleUserID)
            loginError = nil
            withAnimation(.dsSpring) { isAuthenticated = true }
        } catch let error as GIDSignInError where error.code == .canceled {
            return
        } catch {
            loginError = "Google sign-in failed. Please try again."
        }
    }

    // ── Common ────────────────────────────────────────────────────────────────

    func signOut() {
        keychain.delete(kAppleUserID)
        keychain.delete(kGoogleUserID)
        GIDSignIn.sharedInstance.signOut()
        withAnimation(.dsDefault) { isAuthenticated = false }
    }
}
