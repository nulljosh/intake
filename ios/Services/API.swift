import CryptoKit
import Foundation
import Security

/// The same account as the web app: jaybulb-api on Cloudflare (Workers + D1), the client Temida uses.
/// Email and password, Sign in with Apple, Google (code + PKCE in the system web sheet). The refresh
/// token lives in the Keychain; the short-lived access token stays in memory. Shared by iOS and macOS.
@MainActor
final class API {
    static let shared = API()
    static let base = "https://api.jaybulb.com"
    static let site = "https://machaon.jaybulb.com/"
    private static let service = "com.heyitsmejosh.dose.session"

    private(set) var userId: String?
    private(set) var email: String?
    private var access: String?

    private struct Session: Decodable {
        let access_token: String, refresh_token: String
        let user: User
        struct User: Decodable { let id: String; let email: String? }
    }
    private struct Failure: Decodable { let error: String?; let message: String? }

    // MARK: Transport

    @discardableResult
    func call(_ method: String, _ path: String, json: Data? = nil, authed: Bool = true) async throws -> Data {
        var r = URLRequest(url: URL(string: Self.base + path)!)
        r.httpMethod = method
        if let json { r.httpBody = json; r.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if authed, let access { r.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization") }
        let (data, res) = try await URLSession.shared.data(for: r)
        let code = (res as? HTTPURLResponse)?.statusCode ?? 0
        // Access tokens last an hour; refresh once and retry before giving up.
        if code == 401, authed, await refresh() { return try await call(method, path, json: json, authed: true) }
        guard code < 300 else {
            let f = try? JSONDecoder().decode(Failure.self, from: data)
            throw NSError(domain: "Machaon", code: code,
                          userInfo: [NSLocalizedDescriptionKey: f?.error ?? f?.message ?? "Something went wrong (\(code))"])
        }
        return data
    }

    private func body(_ dict: [String: Any]) throws -> Data { try JSONSerialization.data(withJSONObject: dict) }

    // MARK: Session

    private func start(_ data: Data) throws {
        let s = try JSONDecoder().decode(Session.self, from: data)
        access = s.access_token
        Self.keychain(set: s.refresh_token)
        userId = s.user.id
        email = s.user.email
    }

    /// Restores the last session from the Keychain. False means sign in again.
    func refresh() async -> Bool {
        guard let token = Self.keychain() else { return false }
        guard let d = try? await call("POST", "/auth/token?grant_type=refresh_token",
                                      json: try body(["refresh_token": token]), authed: false),
              (try? start(d)) != nil else {
            Self.keychain(set: nil); userId = nil; access = nil; email = nil
            return false
        }
        return true
    }

    /// A current access token for /api/sync, refreshed if this launch has none yet.
    func accessToken() async -> String? {
        if access == nil { _ = await refresh() }
        return access
    }

    func signIn(email: String, password: String) async throws {
        try start(await call("POST", "/auth/token?grant_type=password",
                             json: try body(["email": email, "password": password]), authed: false))
    }

    /// New accounts confirm their email first, so sign-up returns no session.
    func signUp(email: String, password: String) async throws {
        try await call("POST", "/auth/signup",
                       json: try body(["email": email, "password": password, "redirect_to": Self.site]), authed: false)
    }

    /// The reset link opens the web app, which finishes the reset.
    func recover(email: String) async throws {
        try await call("POST", "/auth/recover", json: try body(["email": email, "redirect_to": Self.site]), authed: false)
    }

    func signIn(provider: String, idToken: String, nonce: String? = nil) async throws {
        var b: [String: Any] = ["provider": provider, "id_token": idToken]
        if let nonce { b["nonce"] = nonce }
        try start(await call("POST", "/auth/token?grant_type=id_token", json: try body(b), authed: false))
    }

    func updatePassword(_ password: String) async throws {
        try await call("PUT", "/auth/user", json: try body(["password": password]))
    }

    func signOut() async {
        if access != nil { _ = try? await call("POST", "/auth/logout", json: try? body([:])) }
        userId = nil; access = nil; email = nil
        Self.keychain(set: nil)
    }

    /// Deletes the account. Apple requires this in-app (5.1.1v).
    func deleteAccount() async throws {
        try await call("DELETE", "/auth/user")
        await signOut()
    }

    // MARK: Google: OAuth code flow with PKCE. The iOS client has no secret; the verifier proves
    // this app started the flow. jaybulb-api accepts this client id (Temida, Coda and Atlin use it too).

    static let googleClient = "337798947774-5r4r4ac0f7l10ctimfcig7v8t38ddq4d.apps.googleusercontent.com"
    static var googleScheme: String {
        "com.googleusercontent.apps." + googleClient.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
    }
    private var verifier = ""

    func googleURL() -> URL {
        verifier = (0..<48).map { _ in String(format: "%02x", UInt8.random(in: 0...255)) }.joined()
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        var c = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        c.queryItems = [
            .init(name: "client_id", value: Self.googleClient),
            .init(name: "redirect_uri", value: Self.googleScheme + ":/oauth2redirect"),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: "openid email profile"),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]
        return c.url!
    }

    func finishGoogle(_ callback: URL) async throws {
        guard let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else { throw URLError(.userCancelledAuthentication) }
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let form = ["code": code, "client_id": Self.googleClient, "redirect_uri": Self.googleScheme + ":/oauth2redirect",
                    "grant_type": "authorization_code", "code_verifier": verifier]
        req.httpBody = form.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")" }
            .joined(separator: "&").data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: req)
        struct Tokens: Decodable { let id_token: String? }
        guard let token = try JSONDecoder().decode(Tokens.self, from: data).id_token else { throw URLError(.userAuthenticationRequired) }
        try await signIn(provider: "google", idToken: token)
    }

    // MARK: Keychain
    // Debug builds keep the token in UserDefaults: every ad-hoc re-sign changes the code hash,
    // and the keychain would ask for the login password on each launch.
    #if DEBUG
    private static func keychain(set value: String?) { UserDefaults.standard.set(value, forKey: "debugRefreshToken") }
    private static func keychain() -> String? { UserDefaults.standard.string(forKey: "debugRefreshToken") }
    #else
    private static func keychain(set value: String?) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
        SecItemDelete(q as CFDictionary)
        guard let value else { return }
        SecItemAdd(q.merging([kSecValueData as String: Data(value.utf8)]) { $1 } as CFDictionary, nil)
    }
    private static func keychain() -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                                kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }
    #endif
}
