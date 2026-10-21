import AuthenticationServices
import CryptoKit
import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Sign in with Apple. jaybulb-api lists `com.heyitsmejosh.dose` in APPLE_AUDIENCES, so the native
/// button works with no Apple key on the device. It also keeps Guideline 4.8 satisfied while Google
/// sign-in is offered.
/// ponytail: a flag, not a build config. One edit turns it off, and the code stays compiled.
let appleSignInEnabled = true

/// The signed-in account: the same one the web app uses.
struct User: Equatable {
    let id: String
    let email: String?
}

/// Sign-in, sign-up, reset and delete against jaybulb-api on Cloudflare (moved off Supabase 2026-10-21).
/// Same surface the views used before, so only this file and API.swift know where accounts live.
@Observable
@MainActor
final class AuthService {
    var user: User? = nil
    var isLoading = true
    /// Password resets finish on the web now (the email link opens machaon.jaybulb.com), so this stays
    /// false; NewPasswordView remains for a signed-in password change.
    var isPasswordRecovery = false
    private var currentNonce: String?
    private var webSession: ASWebAuthenticationSession?
    private let api = API.shared

    init() {
        if CommandLine.isUITestSnapshot {
            isLoading = false
            return
        }
        Task { @MainActor in
            if await api.refresh() { syncUser() }
            isLoading = false
        }
    }

    private func syncUser() {
        user = api.userId.map { User(id: $0, email: api.email) }
    }

    func signIn(email: String, password: String) async throws {
        try await api.signIn(email: email, password: password)
        syncUser()
    }

    /// New accounts confirm their email before the first sign-in.
    func signUp(email: String, password: String) async throws {
        try await api.signUp(email: email, password: password)
        do {
            try await api.signIn(email: email, password: password)
            syncUser()
        } catch {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey:
                "Check your email to confirm your account, then sign in."])
        }
    }

    func signOut() async throws {
        await api.signOut()
        user = nil
        isPasswordRecovery = false
    }

    func deleteAccount() async throws {
        try await api.deleteAccount()
        user = nil
    }

    func resetPassword(email: String) async throws {
        try await api.recover(email: email)
    }

    /// Apple hashes the nonce into the identity token; jaybulb-api compares it against the raw
    /// value we send back. Call this from the `SignInWithAppleButton` request closure.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = SHA256.hash(data: Data(nonce.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    func signInWithApple(result: Result<ASAuthorization, Error>) async throws {
        let auth = try result.get()
        guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        try await api.signIn(provider: "apple", idToken: token, nonce: currentNonce)
        currentNonce = nil
        syncUser()
    }

    /// Google: the OAuth code flow in the system web sheet, then the ID token goes to jaybulb-api.
    func signInWithGoogle() async throws {
        let url = api.googleURL()
        let callback: URL = try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: API.googleScheme) { url, error in
                if let url { cont.resume(returning: url) } else { cont.resume(throwing: error ?? URLError(.userCancelledAuthentication)) }
            }
            session.presentationContextProvider = WebAuthAnchor.shared
            webSession = session
            session.start()
        }
        webSession = nil
        try await api.finishGoogle(callback)
        syncUser()
    }

    static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        // ponytail: SecRandomCopyBytes can fail; falling back to a plain random nonce is fine
        // here because the nonce only needs to be unguessable-per-request, not key material.
        if SecRandomCopyBytes(kSecRandomDefault, length, &bytes) != errSecSuccess {
            bytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
        }
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    func updatePassword(_ newPassword: String) async throws {
        try await api.updatePassword(newPassword)
        isPasswordRecovery = false
    }
}

/// Where the Google web sheet attaches: the app's key window.
private final class WebAuthAnchor: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthAnchor()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
        #else
        NSApplication.shared.keyWindow ?? ASPresentationAnchor()
        #endif
    }
}
