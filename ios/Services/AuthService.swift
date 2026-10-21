import AuthenticationServices
import CryptoKit
import Supabase
import Foundation

private func infoPlistValue(_ key: String) -> String? {
    guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
          !value.isEmpty,
          !value.hasPrefix("$(") else { return nil }
    return value
}

/// Non-nil when the bundle is missing its Supabase config. Surfaced in the UI instead of
/// crashing: a `fatalError` here shipped a macOS build that died the moment sign-in loaded,
/// which is what App Review saw as "Sign In will load briefly and then stops".
let supabaseConfigError: String? = {
    let missing = ["SUPABASE_URL", "SUPABASE_ANON_KEY"].filter { infoPlistValue($0) == nil }
    guard !missing.isEmpty else { return nil }
    return "App is misconfigured (missing \(missing.joined(separator: ", "))). Please reinstall or contact support."
}()

/// Sign in with Apple is OFF until the Apple provider is enabled on the shared `spark`
/// Supabase project. Proven disabled 2026-08-18 by a live probe: posting an Apple-issued
/// `iss` to `/auth/v1/token?grant_type=id_token` returns
/// `provider_disabled — Provider (issuer "https://appleid.apple.com") is not enabled`.
/// Shipping the button anyway means every reviewer who taps it gets an error, which is
/// exactly the "Unable to log in" defect that got v1.0 rejected under 2.1(a).
/// Enabled 2026-10-03: the shared Supabase project has the Apple provider on and
/// `com.heyitsmejosh.dose` in its client ID list. Native needs no Apple key. It also keeps
/// Guideline 4.8 satisfied now that Google sign-in is offered on iOS.
/// ponytail: a flag, not a build config. One edit turns it off, and the code stays compiled.
let appleSignInEnabled = true

let supabaseClient = SupabaseClient(
    supabaseURL: URL(string: infoPlistValue("SUPABASE_URL") ?? "https://unconfigured.invalid")!,
    supabaseKey: infoPlistValue("SUPABASE_ANON_KEY") ?? "unconfigured"
)

@Observable
@MainActor
final class AuthService {
    var user: User? = nil
    var isLoading = true
    var isPasswordRecovery = false
    private var currentNonce: String?

    init() {
        if CommandLine.isUITestSnapshot {
            isLoading = false
            return
        }
        Task { @MainActor in
            for await (event, session) in supabaseClient.auth.authStateChanges {
                switch event {
                case .initialSession:
                    user = session?.user
                    isLoading = false
                case .signedIn:
                    user = session?.user
                case .signedOut:
                    user = nil
                    isPasswordRecovery = false
                case .passwordRecovery:
                    user = session?.user
                    isPasswordRecovery = true
                default:
                    break
                }
            }
        }
    }

    /// Every network-backed entry point routes through this, so a misconfigured bundle
    /// reports one readable error instead of failing differently per call site.
    private func requireConfig() throws {
        if let message = supabaseConfigError {
            throw NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    func signIn(email: String, password: String) async throws {
        try requireConfig()
        let session = try await supabaseClient.auth.signIn(email: email, password: password)
        user = session.user
    }

    func signUp(email: String, password: String) async throws {
        try requireConfig()
        let response = try await supabaseClient.auth.signUp(email: email, password: password)
        // The project auto-confirms, so sign-up yields a session immediately; without this the
        // user is left staring at the auth screen after a successful registration.
        if response.session != nil { user = response.user }
    }

    func signOut() async throws {
        try await supabaseClient.auth.signOut()
        user = nil
    }

    /// Calls the shared `delete-account` Edge Function on the spark Supabase project,
    /// which uses the service-role key to delete the authenticated user server-side
    /// (the anon-key client SDK has no permission to delete its own auth user).
    func deleteAccount() async throws {
        let session = try await supabaseClient.auth.session
        var request = URLRequest(url: URL(string: "https://tjsxsqlxjmanwvmywwvw.supabase.co/functions/v1/delete-account")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Couldn't delete account. Try again."])
        }
        try await signOut()
    }

    func resetPassword(email: String) async throws {
        try await supabaseClient.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "healstack://")!
        )
    }

    /// Apple hashes the nonce into the identity token; Supabase compares it against the raw
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
        try requireConfig()
        let auth = try result.get()
        guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        let session = try await supabaseClient.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: token, nonce: currentNonce)
        )
        currentNonce = nil
        user = session.user
    }

    /// Google has no native ID-token path here, so this uses the OAuth browser flow.
    /// `dose://` must stay in the Supabase project's uri_allow_list and in CFBundleURLSchemes
    /// on both platforms, or the callback lands nowhere and the session never arrives.
    func signInWithGoogle() async throws {
        try requireConfig()
        try await supabaseClient.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "healstack://")
        )
        user = try await supabaseClient.auth.session.user
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
        try await supabaseClient.auth.update(
            user: UserAttributes(password: newPassword)
        )
        isPasswordRecovery = false
    }
}
