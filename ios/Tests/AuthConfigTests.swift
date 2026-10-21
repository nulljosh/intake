import XCTest
@testable import Healstack

/// Guards what shipped broken before: sign-in pointing somewhere other than the account the web
/// app uses, and a nonce-less Apple sign-in.
@MainActor
final class AuthConfigTests: XCTestCase {
    func testSignsInAgainstJaybulbAPI() {
        XCTAssertEqual(API.base, "https://api.jaybulb.com")
        XCTAssertTrue(API.googleScheme.hasPrefix("com.googleusercontent.apps."))
    }

    func testNonceIsUniqueAndCorrectLength() {
        let nonces = (0..<200).map { _ in AuthService.randomNonce() }
        XCTAssertTrue(nonces.allSatisfy { $0.count == 32 })
        XCTAssertEqual(Set(nonces).count, nonces.count)
    }
}
