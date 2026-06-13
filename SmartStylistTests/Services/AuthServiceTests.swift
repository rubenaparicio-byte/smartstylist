import AuthenticationServices
import XCTest
@testable import SmartStylist

// MockKeychainStore provides reference-semantic dictionary storage so that
// all closures in KeychainStore share the same underlying data.
private final class MockKeychainBacking {
    var data: [String: String]
    init(_ initial: [String: String] = [:]) { self.data = initial }

    var store: KeychainStore {
        KeychainStore(
            save:   { [unowned self] value, account in self.data[account] = value },
            load:   { [unowned self] account in self.data[account] },
            delete: { [unowned self] account in self.data.removeValue(forKey: account) }
        )
    }
}

@MainActor
final class AuthServiceTests: XCTestCase {

    // ── init ──────────────────────────────────────────────────────────────────

    func test_init_emptyKeychain_notAuthenticated() {
        let svc = AuthService(keychain: MockKeychainBacking().store)
        XCTAssertFalse(svc.isAuthenticated)
    }

    func test_init_appleIDPresent_isAuthenticated() {
        let mock = MockKeychainBacking(["appleUserID": "apple.user.123"])
        let svc = AuthService(keychain: mock.store)
        XCTAssertTrue(svc.isAuthenticated)
    }

    func test_init_googleIDPresent_isAuthenticated() {
        let mock = MockKeychainBacking(["googleUserID": "google.user.456"])
        let svc = AuthService(keychain: mock.store)
        XCTAssertTrue(svc.isAuthenticated)
    }

    func test_init_loginError_isNil() {
        let svc = AuthService(keychain: MockKeychainBacking().store)
        XCTAssertNil(svc.loginError)
    }

    // ── handleError ───────────────────────────────────────────────────────────

    func test_handleError_canceled_doesNotSetLoginError() {
        let svc = AuthService(keychain: MockKeychainBacking().store)
        svc.handleError(ASAuthorizationError(.canceled))
        XCTAssertNil(svc.loginError)
    }

    func test_handleError_invalidResponse_setsLoginError() {
        let svc = AuthService(keychain: MockKeychainBacking().store)
        svc.handleError(ASAuthorizationError(.invalidResponse))
        XCTAssertNotNil(svc.loginError)
    }

    func test_handleError_failed_setsLoginError() {
        let svc = AuthService(keychain: MockKeychainBacking().store)
        svc.handleError(ASAuthorizationError(.failed))
        XCTAssertNotNil(svc.loginError)
    }

    // ── signOut ───────────────────────────────────────────────────────────────

    func test_signOut_clearsAuthentication() {
        let mock = MockKeychainBacking(["appleUserID": "apple.user.123"])
        let svc = AuthService(keychain: mock.store)
        XCTAssertTrue(svc.isAuthenticated)
        svc.signOut()
        XCTAssertFalse(svc.isAuthenticated)
    }

    func test_signOut_removesKeychainEntries() {
        let mock = MockKeychainBacking(["appleUserID": "a", "googleUserID": "g"])
        let svc = AuthService(keychain: mock.store)
        svc.signOut()
        XCTAssertNil(mock.data["appleUserID"])
        XCTAssertNil(mock.data["googleUserID"])
    }

    func test_signOut_whenAlreadyLoggedOut_remainsNotAuthenticated() {
        let svc = AuthService(keychain: MockKeychainBacking().store)
        svc.signOut()
        XCTAssertFalse(svc.isAuthenticated)
    }

    // ── validateAppleCredential ───────────────────────────────────────────────

    func test_validateAppleCredential_noAppleID_setsNotAuthenticated() async {
        let svc = AuthService(keychain: MockKeychainBacking().store)
        await svc.validateAppleCredential()
        XCTAssertFalse(svc.isAuthenticated)
    }

    func test_validateAppleCredential_googleIDPresent_skipsAppleCheck() async {
        // Google session → method returns early, auth state unchanged (true)
        let mock = MockKeychainBacking(["googleUserID": "google.user"])
        let svc = AuthService(keychain: mock.store)
        XCTAssertTrue(svc.isAuthenticated)
        await svc.validateAppleCredential()
        XCTAssertTrue(svc.isAuthenticated)
    }
}
