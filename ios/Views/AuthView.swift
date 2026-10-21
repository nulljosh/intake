import AuthenticationServices
import SwiftUI

struct AuthView: View {
    var authService: AuthService

    @State private var tab: Tab = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var errorMessage: String?
    @State private var successMessage: String?

    enum Tab { case signIn, register, reset }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image("Mark") // the stethoscope from the app icon (brand/mark.svg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)

                    Text("Machaon")
                        .font(.title2.weight(.semibold))

                    Text("Track what you take, and what it does")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if tab != .reset {
                    Picker("", selection: $tab) {
                        Text("Sign in").tag(Tab.signIn)
                        Text("Register").tag(Tab.register)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: tab) { _, _ in
                        errorMessage = nil
                        successMessage = nil
                    }
                } else {
                    HStack {
                        Text("Enter your email and we'll send a reset link.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    if tab != .reset {
                        SecureField("Password", text: $password)
                            .textContentType(tab == .signIn ? .password : .newPassword)
                            .textFieldStyle(.roundedBorder)
                    }

                    if tab == .signIn {
                        HStack {
                            Button("Forgot password?") {
                                errorMessage = nil
                                successMessage = nil
                                tab = .reset
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }

                    if tab == .reset {
                        HStack {
                            Button("Back to sign in") {
                                errorMessage = nil
                                successMessage = nil
                                tab = .signIn
                            }
                            .font(.caption)
                            .foregroundStyle(.tint)
                            Spacer()
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let success = successMessage {
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if loading { ProgressView() }
                        Text(buttonLabel)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(loading || email.isEmpty || (tab != .reset && password.isEmpty))

                if tab == .signIn {
                    Divider()

                    if appleSignInEnabled {
                        SignInWithAppleButton(.signIn) { request in
                            authService.prepareAppleRequest(request)
                        } onCompletion: { result in
                            Task {
                                loading = true
                                defer { loading = false }
                                do { try await authService.signInWithApple(result: result) }
                                // A dismissed sheet is not an error. A device with no Apple ID signed in (typical
                                // of a review device) used to surface Apple's raw error text.
                                catch let error as ASAuthorizationError where error.code == .canceled { }
                                catch is ASAuthorizationError {
                                    errorMessage = "Sign in with Apple isn't available on this device right now. Use email or Google instead."
                                }
                                catch { errorMessage = error.localizedDescription }
                            }
                        }
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 48)
                        .clipShape(Capsule())
                    }

                    Button {
                        Task {
                            loading = true
                            defer { loading = false }
                            do { try await authService.signInWithGoogle() }
                            catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin { }
                            catch { errorMessage = error.localizedDescription }
                        }
                    } label: {
                        // Google's own button: white with a grey outline in light mode, near-black in dark,
                        // the four-colour G on the left. Same height and capsule as the Apple button above.
                        HStack(spacing: 10) {
                            Image("GoogleG").resizable().frame(width: 18, height: 18).accessibilityHidden(true)
                            Text("Sign in with Google").font(.system(size: 17, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(colorScheme == .dark ? Color(white: 0.89) : Color(white: 0.12))
                        .background(colorScheme == .dark ? Color(white: 0.075) : .white, in: Capsule())
                        .overlay(Capsule().stroke(colorScheme == .dark ? Color(white: 0.56) : Color(white: 0.46), lineWidth: 1))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var buttonLabel: String {
        switch tab {
        case .signIn: return "Sign in"
        case .register: return "Create account"
        case .reset: return "Send reset email"
        }
    }

    private func submit() async {
        guard !loading else { return }
        errorMessage = nil
        successMessage = nil
        loading = true
        defer { loading = false }

        do {
            switch tab {
            case .signIn:
                try await authService.signIn(email: email, password: password)
            case .register:
                try await authService.signUp(email: email, password: password)
                successMessage = "Check your email to confirm your account"
            case .reset:
                try await authService.resetPassword(email: email)
                successMessage = "Check your email for a reset link"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
